#!/usr/bin/env python3
"""check-mdx-compat.py — dependency-free lint for markdown that syncs into docs-portal's
Docusaurus/MDX build.

MDX (via Acorn) chokes on Markdown that is perfectly legal CommonMark but not legal MDX:

  1. A bare `{...}` in prose (outside fenced code blocks and outside a single-line inline
     code span) is parsed as a JSX expression container and blows up the build.
  2. A bare `<word...` HTML/JSX-looking tag in prose is parsed as a JSX element open tag.
  3. An inline code span (single backtick pair) that wraps across a newline is invalid
     Markdown-inline-code (backtick spans must not contain a raw newline as far as this
     check is concerned) and regularly hides braces/angle-brackets from proofreading,
     which is exactly how bug #2 above sneaks in.

This script scans *.md files for all three and exits 1 with `file:line: message` output
so pre-commit can catch these before they reach docs-portal's build.

Usage:
    python3 scripts/check-mdx-compat.py [FILE_OR_DIR ...]
    python3 scripts/check-mdx-compat.py --self-test

With no arguments, scans all *.md files under the current directory (skipping the usual
vendor/build dirs). Use --self-test to run the built-in regression fixtures (no pytest
required) and exit non-zero if the detector regresses.
"""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

FENCE_RE = re.compile(r"^\s*(```+|~~~+)")
AUTOLINK_PREFIXES = ("http://", "https://", "mailto:")
SKIP_DIR_NAMES = {
    "node_modules",
    ".git",
    "dist",
    "build",
    ".venv",
    "venv",
    ".next",
    "vendor",
}


@dataclass
class Issue:
    path: str
    line: int
    message: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.message}"


def iter_markdown_files(paths: list[str]) -> list[Path]:
    if not paths:
        paths = ["."]
    files: list[Path] = []
    for raw in paths:
        p = Path(raw)
        if p.is_file():
            files.append(p)
        elif p.is_dir():
            for candidate in sorted(p.rglob("*.md")):
                if any(part in SKIP_DIR_NAMES for part in candidate.parts):
                    continue
                files.append(candidate)
    return files


def check_text(text: str, path: str) -> list[Issue]:
    """Scan one markdown file's text for MDX-compat issues. Split out so the self-test
    can exercise it directly on in-memory fixtures without touching disk."""
    issues: list[Issue] = []
    lines = text.splitlines()

    in_fence = False
    fence_marker = ""

    # Inline-code tracking that persists ACROSS lines, so we can detect a backtick
    # span that opens on one line and doesn't close until a later line.
    in_code = False
    code_open_line = 0

    for lineno, line in enumerate(lines, start=1):
        fence_match = FENCE_RE.match(line)
        if fence_match:
            marker = fence_match.group(1)[0] * 3
            if not in_fence:
                in_fence = True
                fence_marker = marker
            elif marker[0] == fence_marker[0]:
                in_fence = False
                fence_marker = ""
            continue

        if in_fence:
            continue

        # Walk the line char-by-char, splitting into "code" and "prose" runs based on
        # single-backtick inline-code spans (state carries over from previous lines).
        prose_chunks: list[str] = []
        chunk_start = 0
        i = 0
        n = len(line)
        line_had_code_open_before = in_code
        while i < n:
            ch = line[i]
            if ch == "`":
                if not in_code:
                    # Prose up to here.
                    prose_chunks.append(line[chunk_start:i])
                    in_code = True
                    code_open_line = lineno
                else:
                    in_code = False
                chunk_start = i + 1
            i += 1

        if in_code:
            # Span did not close on this line.
            if not line_had_code_open_before:
                # It just opened here — nothing left over as prose after chunk_start,
                # since everything from the backtick onward is (unterminated) code.
                pass
            # Defer the "wraps across newline" report to when it actually closes (or
            # EOF), so we can report the opening line once, not once per line spanned.
        else:
            prose_chunks.append(line[chunk_start:n])

        if not in_code:
            prose_text = "".join(prose_chunks) if prose_chunks else (
                line if chunk_start == 0 else ""
            )
        else:
            prose_text = "".join(prose_chunks)

        # If a span that was open before this line closed during this line, or opened
        # and closed entirely within this line's *other* backtick pairs, report once
        # here at the line where it opened.
        if line_had_code_open_before and not in_code:
            issues.append(
                Issue(
                    path,
                    code_open_line,
                    "inline code span (`...`) opens here but does not close until a "
                    f"later line ({lineno}) — wraps across a newline; use a fenced "
                    "code block instead",
                )
            )

        if not in_code or not line_had_code_open_before:
            issues.extend(_scan_prose(prose_text, path, lineno))

    if in_code:
        issues.append(
            Issue(
                path,
                code_open_line,
                "inline code span (`...`) opened here is never closed in this file",
            )
        )

    return issues


def _scan_prose(text: str, path: str, lineno: int) -> list[Issue]:
    issues: list[Issue] = []
    if not text:
        return issues

    if "{" in text or "}" in text:
        issues.append(
            Issue(
                path,
                lineno,
                "bare '{...}' in prose (outside a fenced/inline code span) — MDX "
                "parses this as a JSX expression; wrap it in backticks or a code "
                "fence: " + text.strip()[:80],
            )
        )

    for m in re.finditer(r"<([A-Za-z][A-Za-z0-9_-]*)(?=[\s/>]|[A-Za-z0-9]*[\s>])", text):
        tag = m.group(1)
        start = m.start()
        # Skip autolinks like <https://...> or <mailto:...>.
        rest = text[start + 1 :]
        if any(rest.startswith(pfx) for pfx in AUTOLINK_PREFIXES):
            continue
        issues.append(
            Issue(
                path,
                lineno,
                f"bare '<{tag}...' HTML/JSX-looking tag in prose (outside code) — "
                "wrap it in backticks: " + text.strip()[:80],
            )
        )

    return issues


def main(argv: list[str]) -> int:
    if "--self-test" in argv:
        return run_self_test()

    files = iter_markdown_files([a for a in argv if not a.startswith("-")])
    all_issues: list[Issue] = []
    for f in files:
        text = f.read_text(encoding="utf-8", errors="replace")
        all_issues.extend(check_text(text, str(f)))

    for issue in all_issues:
        print(issue)

    if all_issues:
        print(f"\n{len(all_issues)} MDX-compat issue(s) found.", file=sys.stderr)
        return 1
    return 0


# --- Self-test -------------------------------------------------------------------
# Real-world regressions this script must catch, taken verbatim from the incidents
# that motivated it (company-os#221):
#
#   1. agent-runtime docs/HISTORY.md, pre-#264: a bare `{repo}#{issue_number}` inside
#      a *quoted string* in prose (not inside any code span) broke the docs-portal
#      MDX build.
#   2. PairSorter README.md, pre-#17: a single-backtick inline code span wrapped
#      across a newline, e.g. `` `{candidates: [{content:\n{parts: ...}]}}]}` `` —
#      the unescaped braces inside it also broke the MDX build once Acorn tried to
#      parse the (accidentally-unterminated) span.

AGENT_RUNTIME_HISTORY_PRE_264 = (
    '**Context:** `notify_approval_waiting` sent only "⏸ Approval waiting — '
    '{repo}#{issue_number} (request {request_id})" + URL — Leo had to open the gate '
    "comment to see WHAT was being approved.\n"
)

PAIRSORTER_README_PRE_17 = (
    "The response the app receives is unchanged (`{candidates: [{content:\n"
    '{parts: [{text: "<JSON array>"}]}}]}`) — no client-side (`src/`) changes\n'
    "were needed for this swap.\n"
)


def run_self_test() -> int:
    failures = 0

    issues = check_text(AGENT_RUNTIME_HISTORY_PRE_264, "HISTORY.md")
    if not any("bare '{...}'" in i.message for i in issues):
        print("FAIL: did not catch agent-runtime HISTORY.md pre-#264 bare-brace regression")
        failures += 1
    else:
        print("PASS: caught agent-runtime HISTORY.md pre-#264 bare-brace regression")

    issues = check_text(PAIRSORTER_README_PRE_17, "README.md")
    if not any("wraps across a newline" in i.message for i in issues):
        print("FAIL: did not catch PairSorter README.md pre-#17 multi-line code-span regression")
        failures += 1
    else:
        print("PASS: caught PairSorter README.md pre-#17 multi-line code-span regression")

    # Sanity: fixed/clean text should NOT trigger.
    clean = (
        "**Context:** `notify_approval_waiting` sent only "
        "`⏸ Approval waiting — {repo}#{issue_number} (request {request_id})` + URL.\n"
    )
    issues = check_text(clean, "HISTORY.md")
    if issues:
        print(f"FAIL: false positive on fixed HISTORY.md text: {issues}")
        failures += 1
    else:
        print("PASS: no false positive on fixed HISTORY.md text")

    clean2 = (
        "The response the app receives follows this structure:\n"
        "\n"
        "```json\n"
        '{"candidates": [{"content": {"parts": [{"text": "<JSON array>"}]}}]}\n'
        "```\n"
    )
    issues = check_text(clean2, "README.md")
    if issues:
        print(f"FAIL: false positive on fixed README.md text: {issues}")
        failures += 1
    else:
        print("PASS: no false positive on fixed README.md text")

    if failures:
        print(f"\n{failures} self-test failure(s).", file=sys.stderr)
        return 1
    print("\nAll self-tests passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
