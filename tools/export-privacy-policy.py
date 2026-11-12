"""Export the bundled privacy policy as the GitHub Pages HTML page."""

import argparse
from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    blocks = (ROOT / "app/privacy-policy.txt").read_text(encoding="utf-8").rstrip("\n").split("\n\n")
    body = []
    for index, block in enumerate(blocks):
        tag = "h1" if index == 0 else (
            "h2" if len(block) < 70 and not any(char in block for char in ".!?@:/\n") else "p")
        content = escape(block).replace("\n", "<br>\n")
        content = content.replace("samuel.nevala@gmail.com",
                                  '<a href="mailto:samuel.nevala@gmail.com">samuel.nevala@gmail.com</a>')
        body.append(f"<{tag}>{content}</{tag}>")
    page = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="light dark">
<title>QShopper privacy policy</title>
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
    output = ROOT / "docs/privacy-policy.html"
    if args.check:
        assert output.read_text(encoding="utf-8") == page, "Privacy page differs from bundled policy; regenerate it"
        print("PASS public HTML matches the bundled privacy policy")
    else:
        output.write_text(page, encoding="utf-8", newline="\n")
        print("Updated docs/privacy-policy.html from app/privacy-policy.txt")


if __name__ == "__main__":
    main()
