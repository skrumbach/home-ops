#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = ["pyyaml>=6,<7", "fonttools>=4.50,<5"]
# ///
"""Draw the two pictures of an app README: `header.svg` and `concept.svg`, next to the README.

Both come from two comments at the top of `kubernetes/apps/base/<ns>/<app>/README.md`:

    <!-- header: icon=shield-check -->
    <!-- concept: From a DNS proof to a certificate | key-round Token | file-key Request | globe Prove -->

The header shows the namespace, the app name and one icon. The concept picture shows three to six
stations (an icon and a short label each) with a pulse travelling through them; without a concept
comment none is written. Icons are Lucide names. Same README, same bytes: nothing here reads the
clock, and the circuit traces are seeded by `<ns>/<app>`. The standard is in scripts/docs/README.md.

Text is drawn as glyph outlines because GitHub blocks fonts inside an SVG image. Motion is CSS only
and stops under `prefers-reduced-motion`.

Usage: scripts/docs/pictures.py [<ns>/<app> ...]   draw (every README that shows header.svg when none is named)
       scripts/docs/pictures.py --check             exit 1 when a picture is missing or older than its comment
"""

from __future__ import annotations

import argparse
import hashlib
import os
import random
import re
import sys
import urllib.request
import xml.etree.ElementTree as ET
from html import escape
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build  # noqa: E402  (the docs generator: one definition of "an app")

ROOT = build.ROOT
VERSION = 1  # bump when the drawing changes, so --check asks for a redraw
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "home-ops-docs"

# The palette and type of docs/assets/css/site.css.
C = {
    "night900": "#060818", "night850": "#090C22", "night800": "#0D102C", "cyan": "#22D8F0", "cyan300": "#7CEFFF",
    "indigo": "#6C5CFF", "violet": "#8B55F5", "violet400": "#A57BFF", "magenta": "#D946E6", "white": "#FFFFFF",
    "ink100": "#E9ECF7", "ink300": "#A9AFCB",
}
FONTS = {  # family -> (fontsource package, weight, sha256 of the latin woff)
    "disp": ("saira", 800, "d6cfbacfe514f9853a39cbcba9044c00ea38fd40e85809abd0425ac3b8fab5bf"),
    "label": ("barlow-semi-condensed", 600, "4b949f7e4f39840f7a80d5bd03a043a7ef9fe36e95d490188738695337df2748"),
    "mono": ("jetbrains-mono", 500, "a270dd0bf13d91053b8999b7c120ffadb59680cfd63fe1a6b388a13bf2809fe1"),
}
FONT_URL = "https://cdn.jsdelivr.net/npm/@fontsource/{pkg}@5.3.0/files/{pkg}-latin-{w}-normal.woff"
ICON_URL = "https://cdn.jsdelivr.net/npm/lucide-static@0.460.0/icons/{name}.svg"
# The icon an app gets when its README names none.
NAMESPACE_ICONS = {
    "actions-runner-system": "play", "ai": "sparkles", "cert-manager": "shield-check", "coder": "square-terminal",
    "database": "database", "downloads": "download", "flux-system": "git-branch", "home-automation": "house",
    "kube-system": "cpu", "media": "clapperboard", "monitoring": "activity", "network": "network", "renovate": "refresh-cw",
    "rook-ceph": "hard-drive", "security": "lock-keyhole", "selfhosted": "box", "system": "server-cog",
    "system-controller": "clock", "system-upgrade": "circle-arrow-up",
}
HEADER_RE = re.compile(r"<!--\s*header:\s*icon=([a-z0-9-]+)\s*-->")
CONCEPT_RE = re.compile(r"<!--\s*concept:\s*(.+?)\s*-->", re.S)
KEY_RE = re.compile(r"<!-- picture v\d+ [^>]*-->")


def die(msg: str) -> None:
    sys.exit(f"pictures.py: {msg}")


def fetch(url: str, dest: Path, sha256: str | None = None) -> Path:
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        try:
            with urllib.request.urlopen(url, timeout=30) as response:
                data = response.read()
        except OSError as exc:
            die(f"download failed: {url}: {exc}")
        dest.write_bytes(data)
    if sha256 and hashlib.sha256(dest.read_bytes()).hexdigest() != sha256:
        die(f"{dest} does not match its pinned checksum; delete it and run again")
    return dest


# --------------------------------------------------------------------------------------------
# Text as outlines

_fonts: dict = {}
_glyphs: dict[tuple[str, str], str] = {}


def font(fam: str):
    from fontTools.ttLib import TTFont

    if fam not in _fonts:
        pkg, weight, sha = FONTS[fam]
        tt = TTFont(fetch(FONT_URL.format(pkg=pkg, w=weight), CACHE / "fonts" / f"{pkg}-{weight}.woff", sha))
        _fonts[fam] = (tt.getGlyphSet(), tt.getBestCmap(), tt["head"].unitsPerEm, tt["hmtx"])
    return _fonts[fam]


def glyph(fam: str, ch: str) -> tuple[str, str]:
    for f in [fam] + [k for k in FONTS if k != fam]:
        cmap = font(f)[1]
        if ord(ch) in cmap:
            return f, cmap[ord(ch)]
    die(f"character {ch!r} is in none of the fonts; rephrase the text")
    raise AssertionError


def measure(s: str, fam: str, size: float, ls: float = 0) -> float:
    width = 0.0
    for ch in s:
        f, g = glyph(fam, ch)
        _, _, upem, hmtx = font(f)
        width += hmtx[g][0] * size / upem + ls * size
    return width - (ls * size if s else 0)


def fit(s: str, fam: str, size: float, maxw: float, ls: float = 0) -> float:
    while size > 10 and measure(s, fam, size, ls) > maxw:
        size -= 1
    return size


def glyph_id(f: str, g: str) -> str:
    """Each glyph outline is defined once per picture, in font units, and placed with <use>."""
    from fontTools.pens.svgPathPen import SVGPathPen

    if (f, g) not in _glyphs:
        pen = SVGPathPen(font(f)[0], ntos=lambda v: str(round(v)))
        font(f)[0][g].draw(pen)
        gid = f"t{len(_glyphs):x}"  # never one of the ids in frame()
        _glyphs[(f, g)] = f'<path id="{gid}" d="{pen.getCommands()}"/>' if pen.getCommands() else f'<g id="{gid}"/>'
    return re.search(r'id="(\w+)"', _glyphs[(f, g)]).group(1)


def glyph_defs() -> str:
    out = "<defs>" + "".join(_glyphs.values()) + "</defs>"
    _glyphs.clear()
    return out


def text(x: float, y: float, s: str, fam: str, size: float, fill: str, ls: float = 0, anchor: str = "start") -> str:
    if anchor == "middle":
        x -= measure(s, fam, size, ls) / 2
    uses = []
    for ch in s:
        f, g = glyph(fam, ch)
        _, _, upem, hmtx = font(f)
        k = size / upem
        if ch.strip():
            uses.append(f'<use href="#{glyph_id(f, g)}" transform="translate({x:.1f} {y:.1f}) scale({k:.5f} {-k:.5f})"/>')
        x += hmtx[g][0] * k + ls * size
    return f'<g fill="{fill}">{"".join(uses)}</g>'


# --------------------------------------------------------------------------------------------
# Shared drawing

def icon(name: str, x: float, y: float, size: float) -> str:
    path = fetch(ICON_URL.format(name=name), CACHE / "icons" / f"{name}.svg")
    try:
        root = ET.fromstring(re.sub(r"<!--.*?-->", "", path.read_text(), flags=re.S))
    except ET.ParseError:
        path.unlink()
        die(f"{name!r} is not a Lucide icon name (https://lucide.dev/icons, release 0.460.0)")
    inner = "".join(f"<{el.tag.split('}')[-1]} " + " ".join(f'{k}="{v}"' for k, v in el.attrib.items()) + "/>" for el in root)
    k = size / 24
    return (f'<g transform="translate({x:.1f} {y:.1f}) scale({k:.3f})" fill="none" stroke="url(#neon)" '
            f'stroke-width="{2.4 / k:.3f}" stroke-linecap="round" stroke-linejoin="round" filter="url(#glow)">{inner}</g>')


def traces(seed: str, x0: float, x1: float, h: float, count: int) -> tuple[str, list[str]]:
    """Faint circuit lines, and each line's path for a pulse to run along."""
    rnd = random.Random(seed)
    out, paths = [], []
    for i in range(count):
        x, y = rnd.uniform(x0, x1), rnd.choice([0, h]) + rnd.uniform(-4, 4)
        pts = [(x, y)]
        for _ in range(rnd.randint(2, 4)):
            if len(pts) % 2:
                y = min(h - 14, max(14, y + rnd.choice([-1, 1]) * rnd.uniform(30, 110)))
            else:
                x = min(x1, max(x0, x + rnd.choice([-1, 1]) * rnd.uniform(40, 160)))
            pts.append((x, y))
        col, op = (C["cyan"], 0.30) if i % 4 == 0 else (C["violet400"], 0.16)
        out.append(f'<polyline points="{" ".join(f"{a:.0f},{b:.0f}" for a, b in pts)}" fill="none" stroke="{col}" '
                   f'stroke-opacity="{op}" stroke-width="1.2"/>'
                   f'<circle cx="{pts[-1][0]:.0f}" cy="{pts[-1][1]:.0f}" r="2.6" fill="{col}" fill-opacity="{op * 2:.2f}"/>')
        paths.append("M" + " L".join(f"{a:.0f} {b:.0f}" for a, b in pts))
    return "".join(out), paths


def frame(w: int, h: int, label: str, key: str, style: str, body: list[str]) -> str:
    """The card every picture sits on: night background, violet and cyan glow, hairline border."""
    defs = f"""<defs>
<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{C['night900']}"/><stop offset="1" stop-color="{C['night850']}"/></linearGradient>
<radialGradient id="gv" cx="88%" cy="0%" r="70%"><stop offset="0" stop-color="{C['violet']}" stop-opacity=".30"/><stop offset="1" stop-color="{C['violet']}" stop-opacity="0"/></radialGradient>
<radialGradient id="gc" cx="0%" cy="100%" r="55%"><stop offset="0" stop-color="{C['cyan']}" stop-opacity=".10"/><stop offset="1" stop-color="{C['cyan']}" stop-opacity="0"/></radialGradient>
<radialGradient id="halo" cx="50%" cy="50%" r="50%"><stop offset="0" stop-color="{C['cyan']}" stop-opacity=".22"/><stop offset=".6" stop-color="{C['violet']}" stop-opacity=".10"/><stop offset="1" stop-color="{C['violet']}" stop-opacity="0"/></radialGradient>
<linearGradient id="neon" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{C['cyan']}"/><stop offset=".5" stop-color="{C['indigo']}"/><stop offset="1" stop-color="{C['magenta']}"/></linearGradient>
<linearGradient id="hair" x1="0" x2="1"><stop offset="0" stop-color="{C['cyan']}" stop-opacity=".8"/><stop offset=".5" stop-color="{C['violet']}" stop-opacity=".6"/><stop offset="1" stop-color="{C['magenta']}" stop-opacity=".8"/></linearGradient>
<linearGradient id="sweep" x1="0" x2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".5" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
<filter id="glow" x="-50%" y="-50%" width="200%" height="200%"><feGaussianBlur stdDeviation="2.4" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<clipPath id="card"><rect width="{w}" height="{h}" rx="8"/></clipPath>
</defs>"""
    card = (f'<rect width="{w}" height="{h}" rx="8" fill="url(#bg)"/><g clip-path="url(#card)">'
            f'<rect width="{w}" height="{h}" fill="url(#gv)"/><rect width="{w}" height="{h}" fill="url(#gc)"/></g>')
    border = f'<rect x=".5" y=".5" width="{w - 1}" height="{h - 1}" rx="8" fill="none" stroke="{C["violet"]}" stroke-opacity=".34"/>'
    drawn = "".join(body)
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}" role="img" '
            f'aria-label="{escape(label, quote=True)}">\n<title>{escape(label)}</title>\n{key}\n{defs}\n<style>{style}</style>\n'
            f'{card}{drawn}{border}{glyph_defs()}\n</svg>\n')


# --------------------------------------------------------------------------------------------
# The two pictures

def header_key(ns: str, app: str, icon_name: str) -> str:
    return f"<!-- picture v{VERSION} header {ns}/{app} icon={icon_name} -->"


def concept_key(ns: str, app: str, line: str) -> str:
    return f"<!-- picture v{VERSION} concept {ns}/{app} {hashlib.sha256(' '.join(line.split()).encode()).hexdigest()[:12]} -->"


def header(ns: str, app: str, icon_name: str) -> str:
    w, h, x = 1200, 140, 48
    title = app.upper()
    size = fit(title, "disp", 58, 860, 0.03)
    lines, paths = traces(f"{ns}/{app}", 760, 1180, h, 11)
    pulses = "".join(f'<circle class="m p{i}" r="2.6" fill="{C["cyan"] if i % 2 == 0 else C["magenta"]}" filter="url(#glow)" '
                     f'style="offset-path:path(\'{p}\')"/>' for i, p in enumerate(paths[:4]))
    style = ("@keyframes run{0%{offset-distance:0%;opacity:0}12%{opacity:1}88%{opacity:1}100%{offset-distance:100%;opacity:0}}"
             "@keyframes breathe{0%,100%{opacity:.55}50%{opacity:1}}"
             "@keyframes sweep{0%{transform:translateX(-160px)}100%{transform:translateX(1200px)}}"
             ".m{animation:run 5s linear infinite}.p1{animation-duration:7s;animation-delay:-2s}"
             ".p2{animation-duration:6s;animation-delay:-4s}.p3{animation-duration:8s;animation-delay:-1s}"
             ".halo{animation:breathe 4s ease-in-out infinite}.sw{animation:sweep 6s ease-in-out infinite}"
             "@media (prefers-reduced-motion:reduce){.m,.sw{display:none}.halo{animation:none}}")
    body = [
        f'<g clip-path="url(#card)">{lines}{pulses}</g>',
        f'<circle class="halo" cx="1084" cy="{h / 2:.0f}" r="80" fill="url(#halo)"/>',
        icon(icon_name, 1084 - 32, h / 2 - 32, 64),
        text(x, 46, f"HOME-OPS  /  {ns.upper()}", "label", 13.5, C["cyan"], 0.22),
        text(x, 62 + size * 0.74, title, "disp", size, C["white"], 0.03),
        f'<rect x="{x}" y="{h - 2}" width="{w - 2 * x}" height="2" fill="url(#hair)"/>',
        f'<g clip-path="url(#card)"><rect class="sw" y="{h - 2}" width="160" height="2" fill="url(#sweep)"/></g>',
    ]
    return frame(w, h, app, header_key(ns, app, icon_name), style, body)


def parse_concept(line: str, where: str) -> tuple[str, list[tuple[str, str]]]:
    parts = [p.strip() for p in line.split("|")]
    steps = []
    for part in parts[1:]:
        name, _, label = part.partition(" ")
        if not re.fullmatch(r"[a-z0-9-]+", name) or not label.strip():
            die(f"{where}: concept station {part!r} is not '<icon> <label>'")
        steps.append((name, label.strip()))
    if not parts[0] or not 3 <= len(steps) <= 6:
        die(f"{where}: a concept comment is 'Title | icon Label | ...' with three to six stations")
    return parts[0], steps


def concept(ns: str, app: str, line: str, where: str) -> str:
    title, steps = parse_concept(line, where)
    w, h, x, y, n = 1200, 250, 48, 132, len(steps)
    xs = [150 + i * (w - 300) / (n - 1) for i in range(n)]
    dur = 1.6 * n
    lines, _ = traces(f"concept:{ns}/{app}", 40, 1160, h, 7)
    rings = []
    for i in range(n):
        at = i / (n - 1) * (n - 1) / n * 100  # when the pulse reaches station i, in percent of the loop
        rings.append(f"@keyframes s{i}{{0%,{max(at - 3, 0):.1f}%{{stroke:{C['violet']};stroke-opacity:.5}}"
                     f"{at + 3:.1f}%{{stroke:{C['cyan']};stroke-opacity:1}}"
                     f"{min(at + 24, 100):.1f}%,100%{{stroke:{C['violet']};stroke-opacity:.5}}}}"
                     f".s{i}{{animation:s{i} {dur:.1f}s linear infinite}}")
    arrive = (n - 1) / n * 100
    style = (f"@keyframes go{{0%{{transform:translateX({xs[0]:.0f}px);opacity:0}}4%{{opacity:1}}"
             f"{arrive:.1f}%{{transform:translateX({xs[-1]:.0f}px);opacity:1}}"
             f"{arrive + 6:.1f}%,100%{{transform:translateX({xs[-1]:.0f}px);opacity:0}}}}"
             f".dot{{animation:go {dur:.1f}s linear infinite}}" + "".join(rings) +
             "@keyframes dash{to{stroke-dashoffset:-24}}.flow{animation:dash 1.2s linear infinite}"
             "@media (prefers-reduced-motion:reduce){.dot{display:none}.flow,.ring{animation:none}}")
    lead = "HOW IT WORKS"
    body = [
        f'<g clip-path="url(#card)">{lines}</g>',
        text(x, 44, lead, "label", 13.5, C["cyan"], 0.22),
        text(x + measure(lead, "label", 13.5, 0.22) + 22, 44, title.upper(), "label", 13.5, C["ink300"], 0.14),
        f'<line x1="{xs[0]:.0f}" y1="{y}" x2="{xs[-1]:.0f}" y2="{y}" stroke="{C["violet"]}" stroke-opacity=".35" stroke-width="1.5"/>',
        f'<line class="flow" x1="{xs[0]:.0f}" y1="{y}" x2="{xs[-1]:.0f}" y2="{y}" stroke="{C["cyan"]}" stroke-opacity=".55" '
        f'stroke-width="1.5" stroke-dasharray="4 20"/>',
        f'<circle class="dot" cy="{y}" r="4.5" fill="{C["cyan300"]}" filter="url(#glow)"/>',
    ]
    for i, (name, label) in enumerate(steps):
        body += [
            f'<circle cx="{xs[i]:.0f}" cy="{y}" r="58" fill="url(#halo)"/>',
            f'<circle class="ring s{i}" cx="{xs[i]:.0f}" cy="{y}" r="38" fill="{C["night800"]}" stroke="{C["violet"]}" '
            f'stroke-opacity=".5" stroke-width="1.6"/>',
            icon(name, xs[i] - 17, y - 17, 34),
            text(xs[i], y - 52, f"{i + 1:02d}", "mono", 12, C["magenta"], 0.08, "middle"),
            text(xs[i], y + 70, label.upper(), "label", fit(label.upper(), "label", 16, (w - 300) / (n - 1) - 24, 0.14),
                 C["ink100"], 0.14, "middle"),
        ]
    alt = f"How {app} works: {title}. " + ", ".join(f"{i + 1} {label}" for i, (_, label) in enumerate(steps)) + "."
    return frame(w, h, alt, concept_key(ns, app, line), style, body)


# --------------------------------------------------------------------------------------------
# Which apps, and the comments in their READMEs

def app_dirs() -> dict[tuple[str, str], Path]:
    dirs = {}
    for key, app in build.load_apps().items():
        base = sorted({"/".join(k["path"].split("/")[:5]) for k in app["ks"] if k["path"].startswith("kubernetes/apps/base/")})
        if base:
            dirs[key] = ROOT / base[0]
    return dirs


def wanted(key: tuple[str, str], readme: Path) -> dict[str, tuple[str, str]]:
    """File name -> (key comment, the input it is drawn from) for the pictures this README asks for.

    A README that shows no `header.svg` is not in the standard yet and gets nothing.
    """
    source = readme.read_text()
    if "header.svg" not in source:
        return {}
    icon_match, concept_match = HEADER_RE.search(source), CONCEPT_RE.search(source)
    icon_name = icon_match.group(1) if icon_match else NAMESPACE_ICONS.get(key[0], "box")
    out = {"header.svg": (header_key(*key, icon_name), icon_name)}
    if concept_match:
        out["concept.svg"] = (concept_key(*key, concept_match.group(1)), concept_match.group(1))
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("apps", nargs="*", metavar="NS/APP", help="apps to draw (default: every README that shows header.svg)")
    parser.add_argument("--check", action="store_true", help="report pictures that are missing or out of date, draw nothing")
    args = parser.parse_args()

    dirs = app_dirs()
    keys = sorted(dirs)
    if args.apps:
        keys = [tuple(a.split("/", 1)) for a in args.apps]
        if unknown := [a for a, k in zip(args.apps, keys) if k not in dirs]:
            die(f"not an app (kubernetes/apps/main/<ns>/<app>.yaml): {', '.join(unknown)}")
    stale, drawn = [], 0
    for key in keys:
        readme = dirs[key] / "README.md"
        if not readme.is_file():
            if args.apps:
                die(f"{readme.relative_to(ROOT)} does not exist")
            continue
        want = wanted(key, readme)
        if "concept.svg" not in want and (dirs[key] / "concept.svg").exists():
            stale.append(f"{(dirs[key] / 'concept.svg').relative_to(ROOT)}: the README has no concept comment; delete the file")
        for name, (key_comment, source) in want.items():
            path = dirs[key] / name
            found = KEY_RE.search(path.read_text()) if path.exists() else None
            if found and found.group(0) == key_comment:
                continue
            if args.check:
                stale.append(f"{path.relative_to(ROOT)}: {'out of date' if found else 'missing'}")
                continue
            where = str(readme.relative_to(ROOT))
            path.write_text(header(*key, source) if name == "header.svg" else concept(*key, source, where))
            drawn += 1
            print(f"drew {path.relative_to(ROOT)}")
    for line in stale:
        print(f"STALE {line}", file=sys.stderr)
    if not args.check:
        print(f"pictures.py: {drawn} drawn, {len(keys)} apps looked at")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
