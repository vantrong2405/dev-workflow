"""Run OpenSpec inside a project's Vibe workspace."""

import argparse
import fcntl
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from contextlib import contextmanager
from pathlib import Path


class VibeError(Exception):
    pass


def run(command, *, cwd=None, env=None):
    result = subprocess.run(
        command, cwd=cwd, capture_output=True, text=True,
        env={**os.environ, "OPENSPEC_TELEMETRY": "0", **(env or {})},
    )
    if result.returncode:
        raise VibeError((result.stderr + result.stdout).strip() or f"Failed: {command[0]}")
    return result.stdout


def openspec(home, *args):
    return run(["openspec", *args], cwd=home)


def verify_paths(home):
    for path in (home, home / "openspec", home / "openspec/config.yaml", home / "openspec/specs",
                 home / "openspec/changes", home / "openspec/changes/archive", home / "openspec/schemas"):
        if path.is_symlink():
            raise VibeError(f"Expected a local path inside the Vibe workspace: {path}")


def workspace_state(home):
    verify_paths(home)
    if not (home / "openspec/config.yaml").is_file():
        raise VibeError("Vibe specs are not initialized. Open a Vibe change first.")
    state = json.loads(openspec(home, "list", "--json"))
    root = state.get("root") or {}
    if not root.get("path") or Path(root["path"]).resolve() != home.resolve():
        raise VibeError(f"OpenSpec resolved outside the Vibe workspace: {root.get('path')}")
    return state


@contextmanager
def project_lock(project):
    with (project / ".vibe-specs.lock").open("a", encoding="utf-8") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def initialize(home, template_root):
    verify_paths(home)
    if not template_root.is_dir():
        raise VibeError("Vibe schema template extensions are missing from this installation.")
    if not (home / "openspec" / "config.yaml").exists():
        home.mkdir(exist_ok=True)
        openspec(home, "init", str(home), "--tools", "none", "--no-animation")
    workspace_state(home)
    schema = home / "openspec/schemas/vibe"
    if not (schema / "schema.yaml").is_file():
        openspec(home, "schema", "fork", "spec-driven", "vibe", "--json")
    for suffix in sorted(template_root.glob("*.md")):
        path = schema / "templates" / suffix.name
        original = path.read_text(encoding="utf-8")
        marker = "<!-- ak:vibe template extension -->"
        if marker not in original:
            content = f"{original.rstrip()}\n\n{marker}\n{suffix.read_text(encoding='utf-8')}"
            temp = path.with_suffix(".tmp")
            temp.write_text(content, encoding="utf-8")
            temp.replace(path)


def archive_matches(changes, name):
    return sorted((changes / "archive").glob(f"????-??-??-{name}"))


def change_revision(change):
    paths = [change / name for name in ("proposal.md", "design.md", "tasks.md")]
    deltas = sorted((change / "specs").rglob("spec.md"))
    if not deltas:
        raise VibeError("A Vibe change needs a business spec delta.")
    digest = hashlib.sha256()
    if change.is_symlink():
        raise VibeError(f"Expected a local Vibe change directory: {change}")
    for path in [*paths, *deltas]:
        if not path.is_file() or not path.resolve().is_relative_to(change.resolve()):
            raise VibeError(f"Missing or external planning artifact: {path}")
        content = path.read_bytes()
        if path.name == "tasks.md":
            content = re.sub(rb"(?m)^([ \t]*- \[)[xX ](\])", rb"\1 \2", content)
        digest.update(str(path.relative_to(change)).encode() + b"\0" + hashlib.sha256(content).digest())
    main_specs = change.parent.parent / "specs"
    for delta in deltas:
        relative = delta.relative_to(change / "specs")
        current = main_specs / relative
        if not current.resolve().is_relative_to(main_specs.resolve()):
            raise VibeError(f"Expected a local business spec: {current}")
        baseline = hashlib.sha256(current.read_bytes()).digest() if current.is_file() else b"missing"
        digest.update(f"baseline/{relative}".encode() + b"\0" + baseline)
    return digest.hexdigest()


def archive(home, changes, name, project, project_slug, scripts):
    state = workspace_state(home)
    change = changes / name
    if not change.is_dir():
        archived = archive_matches(changes, name)
        if archived and (archived[-1] / "verification.json").is_file():
            return {"status": "already-archived", "archive": str(archived[-1])}
        raise VibeError(f"No active Vibe change: {name}")
    active = next((item for item in state["changes"] if item["name"] == name), None)
    if not active or active["totalTasks"] < 1 or active["completedTasks"] != active["totalTasks"]:
        raise VibeError("Complete the Vibe checklist with verified work before archiving.")
    ticket = (change / ".vibe-ticket").read_text(encoding="utf-8").strip()
    if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", ticket):
        raise VibeError("Invalid linked ak ticket in .vibe-ticket.")
    worklog = project / "worklogs" / ticket
    revision = change_revision(change)
    plan = (worklog / "04-plan.md").read_text(encoding="utf-8")
    if f"- **Vibe spec revision:** {revision}" not in plan.splitlines():
        raise VibeError("The business spec or planned work has changed. Refresh the plan and Redteam review.")
    openspec(home, "validate", name, "--type", "change", "--strict", "--json")
    gates = json.loads(run([
        "bash", str(scripts / "check-gates.sh"), ticket, "--project", project_slug,
        "--min", "tests", "--require-plan-review", "--json",
    ], env={"AK_WORKSPACES_ROOT": str(project.parent)}))
    if not gates["ok"] or Path(gates["worklog"]).resolve() != worklog.resolve():
        raise VibeError("The verified ticket does not match this Vibe change and project.")
    if any(warning.startswith("G8 WAIVED:") for warning in gates["warns"]):
        raise VibeError("The Vibe spec library needs test evidence; this ticket used a G8 waiver.")
    # Keep the proof with the change so completion remains readable after worklog cleanup.
    (change / "verification.json").write_text(
        json.dumps({"ticket": ticket, "specRevision": revision, "gates": gates}, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    result = json.loads(openspec(home, "archive", name, "--yes", "--json"))
    archived = archive_matches(changes, name)
    if change.exists() or not archived:
        raise VibeError(f"OpenSpec did not archive {name}: {result}")
    return {"status": "archived", "archive": str(archived[-1]), "ticket": ticket}


def parse_args(argv):
    parser = argparse.ArgumentParser(prog="vibe-specs.sh", description=__doc__)
    verbs = parser.add_subparsers(dest="action", required=True)
    verbs.add_parser("list").add_argument("--specs", action="store_true")
    verbs.add_parser("show-spec").add_argument("capability")
    create = verbs.add_parser("new")
    create.add_argument("change")
    create.add_argument("ticket")
    for verb in ("status", "revision", "validate", "archive"):
        verbs.add_parser(verb).add_argument("change")
    instructions = verbs.add_parser("instructions")
    instructions.add_argument("change")
    instructions.add_argument("artifact", choices=("proposal", "design", "specs", "tasks"))
    args = parser.parse_args(argv)
    if hasattr(args, "change") and not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.change):
        parser.error("change names must be lowercase kebab-case")
    if hasattr(args, "ticket") and not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", args.ticket):
        parser.error("invalid ak ticket ID")
    if hasattr(args, "capability") and not re.fullmatch(r"[a-z0-9-]+(?:/[a-z0-9-]+)*", args.capability):
        parser.error("invalid capability path")
    return args


def main(project, slug, scripts, argv):
    args = parse_args(argv)
    if not shutil.which("openspec"):
        raise VibeError("The OpenSpec CLI is required for the Vibe spec library.")
    home = project / "vibe"
    verify_paths(home)
    changes = home / "openspec/changes"
    if args.action == "list" and not (home / "openspec/config.yaml").exists():
        print(json.dumps({"specs" if args.specs else "changes": [], "root": None}))
        return
    if args.action == "new":
        with project_lock(project):
            if not (project / "worklogs" / args.ticket / "INDEX.md").is_file():
                raise VibeError(f"Create the ak worklog for {args.ticket} before linking a Vibe change.")
            templates = scripts.parent / "templates/vibe/spec-archive"
            if not templates.is_dir():
                templates = scripts.parent / "shared/templates/vibe/spec-archive"
            initialize(home, templates)
            change = changes / args.change
            if change.is_symlink():
                raise VibeError(f"Expected a local Vibe change directory: {change}")
            if archive_matches(changes, args.change):
                raise VibeError("This Vibe change has already been archived. Choose a new change name.")
            link = change / ".vibe-ticket"
            if not change.exists():
                openspec(home, "new", "change", args.change, "--schema", "vibe")
                link.write_text(args.ticket + "\n", encoding="utf-8")
            elif not link.is_file() or link.read_text(encoding="utf-8").strip() != args.ticket:
                raise VibeError(f"Vibe change {args.change} is associated with a different or missing ticket.")
            print(json.dumps({"change": args.change, "ticket": args.ticket, "path": str(change)}))
        return
    if args.action == "archive":
        with project_lock(project):
            print(json.dumps(archive(home, changes, args.change, project, slug, scripts)))
        return
    state = workspace_state(home)
    if args.action == "list":
        print(openspec(home, "list", "--specs", "--json") if args.specs else json.dumps(state))
    elif args.action == "show-spec":
        print(openspec(home, "show", args.capability, "--type", "spec"), end="")
    elif args.action == "status":
        print(openspec(home, "status", "--change", args.change, "--json"), end="")
    elif args.action == "instructions":
        print(openspec(home, "instructions", args.artifact, "--change", args.change, "--json"), end="")
    elif args.action == "validate":
        print(openspec(home, "validate", args.change, "--type", "change", "--strict", "--json"), end="")
    elif args.action == "revision":
        print(change_revision(changes / args.change))


if __name__ == "__main__":
    try:
        main(Path(sys.argv[1]).resolve(), sys.argv[2], Path(sys.argv[3]), sys.argv[4:])
    except (VibeError, OSError, ValueError, KeyError) as error:
        print(f"ERROR: {error}", file=sys.stderr)
        sys.exit(1)
