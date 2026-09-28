# QPC Hafs Page Glyph (V4, 1441H print, with tajweed)

- **Riwaya:** hafs
- **Counting system:** Kufi
- **Kind:** page-glyph
- **Source:** quranpedia.net mushaf tables

## Files

- `quran.json` / `.csv` / `.txt` / `.sql` — reference Unicode text (safe Arabic), for search/display with any Unicode Arabic font.
- `quran-glyphs.json` — per-ayah PUA chunks: `surah`, `ayah`, `chunks: [{p, family, file, text}]`. This is the rendering source for this font.
- `quran-glyphs.csv` — flattened: one row per chunk with `surah, ayah, chunk, p, family, file, text`.
- `quran-glyphs.sql` — `CREATE TABLE glyph_chunks …; INSERT …;`.
- `fonts.css` — pre-generated `@font-face` for every per-page file in `font/`.
- `font/` — 53 per-page font files (each glyph is pinned to the specific page it appears on).

## Usage (CSS)

Use locally from this bundle:

```html
<link rel="stylesheet" href="./fonts.css">
```

Or skip the download entirely and reference the live bundle:

```html
<link rel="stylesheet" href="https://fonts.quran.ws/bundles/qpc-hafs-v4/fonts.css">
<script>
const data = await fetch('https://fonts.quran.ws/bundles/qpc-hafs-v4/quran-glyphs.json').then(r => r.json());
</script>
```

Render an ayah by walking its `chunks` and switching `font-family` per chunk's `family`:

```js
// Render (s,v) from quran-glyphs.json
const record = data.ayat.find(a => a.surah === 22 && a.ayah === 1);
const html = record.chunks
    .map(c => `<span style="font-family:'${c.family}'">${c.text}</span>`)
    .join('');
document.querySelector('.quran').innerHTML = html;
```

Container CSS — these fonts encode pre-shaped words as Private-Use-Area codepoints, so RTL context + bidi-override + wrap hints are required:

```css
.quran {
    direction: rtl;
    unicode-bidi: bidi-override;
    text-align: center;
    overflow-wrap: anywhere;
    word-break: break-word;
    font-size: 2rem;
    line-height: 2.3;
}
```

> **Page-glyph note:** this font encodes pre-shaped words as Private-Use-Area codepoints. Pair it with the matching `quran_ayat_full` / `glyph_ayat` data (not the plain `quran.txt`) to render a mushaf page accurately.


License: fonts © KFGQPC. Text © quranpedia.net contributors. See each project for terms.