"""Export the canonical app terms as the GitHub Pages HTML page."""

import argparse
from html import escape
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    source = (ROOT / "store/google-play/TERMS.md").read_text(encoding="utf-8")
    assert "TO COMPLETE" not in source and "Draft for owner review" not in source
    body = []
    for block in source.strip().split("\n\n"):
        heading = re.fullmatch(r"(#{1,2}) (.+)", block)
        tag, text = ("h" + str(len(heading[1])), heading[2]) if heading else ("p", block)
        content = escape(text)
        content = re.sub(r"\[([^\]]+)\]\((https://[^\s)]+|mailto:[^\s)]+|tel:[^\s)]+)\)",
                         r'<a href="\2">\1</a>', content)
        content = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", content)
        body.append(f"<{tag}>{content}</{tag}>")
    page = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>QShopper app terms</title>
<style>
body { font-family: system-ui, sans-serif; line-height: 1.6; margin: 2rem auto;
       padding: 0 1.2rem; max-width: 48rem; overflow-wrap: anywhere; }
h1, h2 { line-height: 1.25; }
h2 { margin-top: 2rem; font-size: 1.25rem; }
a { color: light-dark(#075a36, #69f0ae); }
</style>
</head>
<body>
<main>
""" + "\n".join(body) + "\n</main>\n</body>\n</html>\n"
    output = ROOT / "docs/terms.html"
    if args.check:
        assert output.read_text(encoding="utf-8") == page, "Terms page differs from canonical Markdown; regenerate it"
        print("PASS public HTML matches the canonical app terms")
    else:
        output.write_text(page, encoding="utf-8", newline="\n")
        print("Updated docs/terms.html from store/google-play/TERMS.md")


if __name__ == "__main__":
    main()
