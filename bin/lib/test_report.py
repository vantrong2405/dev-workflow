"""Read local JUnit evidence without treating a failed report as a passing check."""

import sys
from xml.etree import ElementTree


def junit_cases(path):
    root = ElementTree.parse(path).getroot()
    if root.tag not in {"testsuite", "testsuites"}:
        raise ValueError("expected JUnit XML")
    for node in root.iter():
        if node.tag in {"failure", "error"}:
            raise ValueError("JUnit reports failures/errors")
        if node.tag in {"testsuite", "testsuites"}:
            if any(int(node.get(field, "0")) != 0 for field in ("failures", "errors")):
                raise ValueError("JUnit reports failures/errors")
    return list(root.iter("testcase"))


if __name__ == "__main__":
    try:
        cases = junit_cases(sys.argv[1])
        if not any(case.find("skipped") is None for case in cases):
            raise ValueError("JUnit contains no executed test cases")
    except (OSError, ValueError, ElementTree.ParseError) as error:
        print(error, file=sys.stderr)
        sys.exit(1)
