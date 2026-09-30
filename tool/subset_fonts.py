#!/usr/bin/env python3
"""Builds the fonts bundled for the web app (see issue #12).

The web renderer can't use system fonts, and by default fetches Roboto and
Noto Color Emoji from fonts.gstatic.com. We ship small subsets instead:

* Roboto-{400,500,600,700}.ttf — Roboto, Latin only. Registered as family
  "Roboto", so the web engine doesn't download its own fallback Roboto.
* LighthouseEmoji.ttf — Noto Color Emoji with exactly the habit symbols the
  app offers (read from the Dart sources), plus ✓ mapped to ✔.

Rerun after changing the symbol catalog:

    pip install fonttools
    python3 tool/subset_fonts.py <dir with Roboto-400.ttf … Roboto-700.ttf
                                  and NotoColorEmoji.ttf>

Source fonts: the static Roboto weights and Noto Color Emoji (COLRv1) as
served by Google Fonts. Both are SIL Open Font License 1.1 — see
assets/fonts/*-OFL.txt.
"""

import pathlib
import re
import sys

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'fonts'

# Google Fonts' "latin" range: enough for German and English text,
# typographic quotes, dashes, ellipsis, € and arrows.
LATIN = (
    'U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,'
    'U+0304,U+0308,U+0329,U+2000-206F,U+2074,U+20AC,U+2122,U+2190-2199,'
    'U+2191,U+2193,U+2212,U+2215,U+FEFF,U+FFFD'
)

# Where the app's habit symbols are defined.
SYMBOL_SOURCES = [
    ROOT / 'lib' / 'widgets' / 'habit_editor_sheet.dart',
    ROOT / 'lib' / 'state' / 'lighthouse_controller.dart',
]


def habit_symbols():
    symbols = set()
    for path in SYMBOL_SOURCES:
        text = path.read_text(encoding='utf-8')
        symbols |= set(re.findall(r"char: '([^']+)'", text))  # catalog
        symbols |= set(re.findall(r"'[a-zäöü]+': '([^']+)'", text))  # hints
        symbols |= set(re.findall(r"emoji: '([^']+)'", text))  # defaults
    return sorted(symbols)


def subset_font(source, target, unicodes, remove_tables=()):
    opts = subset.Options()
    opts.layout_features = ['*']
    opts.name_IDs = ['*']
    opts.notdef_outline = True
    opts.hinting = False
    font = subset.load_font(str(source), opts)
    for tag in remove_tables:
        if tag in font:
            del font[tag]
    subsetter = subset.Subsetter(opts)
    subsetter.populate(unicodes=unicodes)
    subsetter.subset(font)
    subset.save_font(font, str(target), opts)


def main(source_dir):
    source_dir = pathlib.Path(source_dir)
    OUT.mkdir(parents=True, exist_ok=True)

    latin = subset.parse_unicodes(LATIN)
    for weight in (400, 500, 600, 700):
        subset_font(
            source_dir / f'Roboto-{weight}.ttf',
            OUT / f'Roboto-{weight}.ttf',
            latin,
        )

    symbols = habit_symbols()
    codepoints = sorted({ord(ch) for s in symbols for ch in s} | {0x2714})
    emoji = OUT / 'LighthouseEmoji.ttf'
    # COLR/CPAL vector glyphs are what the web renderer draws; the SVG copy
    # of every glyph would only add size.
    subset_font(
        source_dir / 'NotoColorEmoji.ttf',
        emoji,
        codepoints,
        remove_tables=['SVG '],
    )

    # ✓ (the app's default symbol) isn't in the emoji font — show ✔ instead.
    font = TTFont(str(emoji))
    for table in font['cmap'].tables:
        if table.isUnicode() and 0x2714 in table.cmap:
            table.cmap[0x2713] = table.cmap[0x2714]
    font.save(str(emoji))

    print(f'{len(symbols)} habit symbols, {len(codepoints)} code points')
    for path in sorted(OUT.glob('*.ttf')):
        print(f'  {path.name}: {path.stat().st_size // 1024} KB')


if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
