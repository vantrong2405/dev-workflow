"""Validate a ticket's browser evidence and, for visual changes, its golden runs."""

import json
import re
import sys
from datetime import datetime
from pathlib import Path
from urllib.parse import urlsplit
from xml.etree import ElementTree


SOURCE = re.compile(r"(?:commit|worktree):[0-9a-f]{40}(?:[0-9a-f]{24})?")
CASE_ID = re.compile(r"(?:AC|NEG|PERM|EDGE)-[0-9]+")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def required_text(record, key):
    value = record.get(key)
    require(
        isinstance(value, str) and value.strip() and
        value.strip().lower() not in {"tbd", "todo", "n/a", "unknown", "…", "..."},
        f"missing concrete {key}",
    )
    return value.strip()


def artifact(root, value):
    relative = Path(value)
    require(not relative.is_absolute() and relative.parts[:1] == ("evidence",)
            and ".." not in relative.parts, f"expected a ticket evidence path: {value}")
    path = (root / relative).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        raise ValueError(f"artifact escapes the worklog: {value}") from None
    require(path.is_file() and path.stat().st_size > 0, f"missing or empty artifact: {value}")
    return path


def capture_file(root, value, allow_video=False):
    path = artifact(root, value)
    with path.open("rb") as stream:
        signature = stream.read(12)
    require(
        signature.startswith((b"\x89PNG\r\n\x1a\n", b"\xff\xd8\xff"))
        or (signature.startswith(b"RIFF") and signature[8:12] == b"WEBP")
        or (allow_video and signature.startswith(b"\x1a\x45\xdf\xa3")),
        f"unsupported capture format: {value}",
    )
    return path


def browser_run(root, run, result):
    require(run.get("result") == result, f"expected a browser run with result {result}")
    required_text(run, "tool")
    required_text(run, "observed")
    source = required_text(run, "source")
    require(SOURCE.fullmatch(source), "invalid browser source identity")
    when = datetime.fromisoformat(required_text(run, "checked_at").replace("Z", "+00:00"))
    require(when.utcoffset() is not None, "browser run time needs a timezone")
    capture = capture_file(root, required_text(run, "capture"), allow_video=True)
    log = artifact(root, required_text(run, "log"))
    require(capture != log, "browser capture and log must be separate files")
    return when, source, capture, log


def golden_run(root, run, source, captures):
    required_text(run, "approval")
    required_text(run, "command")
    require(type(run.get("exit_code")) is int and run["exit_code"] == 0,
            "golden comparison command must exit successfully")
    require(run.get("source") == source, "golden run does not match the tested source")
    baseline = capture_file(root, required_text(run, "baseline"))
    require(baseline not in captures, "golden baseline must be separate from browser captures")
    report = ElementTree.parse(artifact(root, required_text(run, "report")))
    require(report.getroot().tag in {"testsuite", "testsuites"}, "golden report must be JUnit XML")
    test_name = required_text(run, "test")
    matches = [case for case in report.iter("testcase") if case.get("name") == test_name]
    require(len(matches) == 1, f"golden report needs exactly one test named {test_name}")
    require(all(child.tag not in {"failure", "error", "skipped"} for child in matches[0]),
            f"golden test did not pass: {test_name}")


def verify(root, spec, phase, is_bug, is_visual, source):
    manifest = artifact(root, "evidence/ui-verification.json")
    cases = json.loads(manifest.read_text(encoding="utf-8")).get("cases")
    require(isinstance(cases, list) and cases, "UI evidence needs at least one browser case")
    spec_ids = set(re.findall(
        r"^\s*\|\s*((?:AC|NEG|PERM|EDGE)-[0-9]+)\s*\|",
        spec.read_text(encoding="utf-8"), re.MULTILINE,
    ))
    seen = set()
    has_golden = False
    for case in cases:
        case_id = required_text(case, "id")
        require(CASE_ID.fullmatch(case_id) and case_id in spec_ids and case_id not in seen,
                f"missing, unknown or duplicate UI case ID: {case_id}")
        seen.add(case_id)
        try:
            url = urlsplit(required_text(case, "url"))
            require(url.scheme in {"http", "https"} and url.hostname and url.username is None,
                    "browser URL must be HTTP(S) without embedded credentials")
            require(re.fullmatch(r"[1-9][0-9]*x[1-9][0-9]*", required_text(case, "viewport")),
                    "viewport must be WIDTHxHEIGHT")
            for key in ("actor", "locale", "steps", "expected"):
                required_text(case, key)
            before = browser_run(root, case.get("before", {}), "REPRODUCED") if is_bug else None
            if phase == "before":
                continue
            after = browser_run(root, case.get("after", {}), "PASS")
            require(SOURCE.fullmatch(source) and after[1] == source,
                    "browser run does not match the current tested source")
            if before:
                require(before[0] < after[0] and before[1] != after[1],
                        "before and after need ordered run times and distinct source states")
                require(before[2] != after[2] and before[3] != after[3],
                        "before and after need separate captures and logs")
            if is_visual and case.get("golden") is not None:
                captures = {after[2]} | ({before[2]} if before else set())
                golden_run(root, case.get("golden", {}), source, captures)
                has_golden = True
        except (ValueError, OSError, AttributeError, TypeError, ElementTree.ParseError) as error:
            raise ValueError(f"{case_id}: {error}") from None
    if phase == "after" and is_visual:
        require(has_golden, "visual changes require an approved golden comparison")


if __name__ == "__main__":
    worklog, spec_file, phase, bug, visual, tested_source = sys.argv[1:]
    try:
        verify(Path(worklog).resolve(), Path(spec_file), phase, bug == "yes", visual == "yes", tested_source)
    except (ValueError, OSError, AttributeError, TypeError) as error:
        print(f"UI evidence: {error}", file=sys.stderr)
        sys.exit(1)
