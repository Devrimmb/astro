#!/usr/bin/env python3
"""
AI ile üretilmiş açı yorumu Markdown dosyalarını `aspects.json`'a aktarır.

Beklenen biçim (her kayıt `---` ile ayrılır):

    ## sun / moon
    ### Güneş-Ay Kavuşumu
    `sun / moon` · `conjunction`
    > Kısa özet
    **🌙 Duygusal Açı**
    ...açıklama...
    **🌟 Olumlu Etkiler**
    • ...
    **⚠️ Zorlayıcı Etkiler**
    • ...
    **🔑 Anahtar Kelimeler**
    A · B · C
    **🌱 Tavsiye**
    ...

Her kayıt için `title`, `short`, `detailed` (özetten sonraki tüm markdown),
`strengths`, `challenges`, `advice`, `category`, `keywords` yazılır. Mevcut anahtar
(ör. `sun_moon` → `conjunction`) varsa yerine konur, yoksa eklenir; diğer kayıtlara
dokunulmaz.

Kullanım:
    python3 tools/import_aspect_md.py ~/Desktop/gunes_*.md            # aktar
    python3 tools/import_aspect_md.py --dry-run ~/Desktop/gunes_*.md  # yalnızca doğrula
Sonra:
    python3 tools/generate_interpretations_html.py
"""

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ASPECTS = ROOT / "AstroApp" / "Core" / "Interpretation" / "Data" / "aspects.json"

# Planet.identifier + ChartPoint (mc/asc) ile aynı adlar
POINTS = [
    "sun", "moon", "mercury", "venus", "mars", "jupiter", "saturn", "uranus",
    "neptune", "pluto", "north_node", "chiron", "lilith", "part_of_fortune",
    "ceres", "pallas", "juno", "vesta", "mc", "asc",
]
ASPECT_TYPES = {
    "conjunction", "sextile", "square", "trine", "opposition",
    "semi_sextile", "semi_square", "sesquiquadrate", "quincunx",
}


def pair_key(raw: str) -> str:
    """'sun / north / node' → 'sun_north_node' (iki geçerli noktaya bölünebilmeli)."""
    joined = "_".join(t.strip() for t in raw.split("/") if t.strip())
    for p1 in POINTS:
        if joined.startswith(p1 + "_") and joined[len(p1) + 1:] in POINTS:
            return joined
    raise ValueError(f"nokta çifti tanınmadı: {raw!r}")


def section_after(lines: list[str], marker: str) -> list[str]:
    """`**… marker**` başlığından sonraki, bir sonraki `**…**` başlığına kadar olan satırlar."""
    out, inside = [], False
    for line in lines:
        is_header = line.startswith("**") and line.rstrip().endswith("**")
        if is_header and marker in line:
            inside = True
            continue
        if inside and is_header:
            break
        if inside:
            out.append(line)
    return [l for l in out if l.strip()]


def parse_entry(block: str, source: str) -> tuple[str, str, dict]:
    lines = [l.rstrip() for l in block.strip().splitlines()]
    where = f"{source}: {lines[0] if lines else '?'}"

    title = next((l[4:].strip() for l in lines if l.startswith("### ")), None)
    meta = next((l for l in lines if l.startswith("`") and "·" in l), None)
    short_idx = next((i for i, l in enumerate(lines) if l.startswith("> ")), None)
    if not (title and meta and short_idx is not None):
        raise ValueError(f"{where}: başlık / `çift · açı` / '>' özet satırı eksik")

    codes = re.findall(r"`([^`]+)`", meta)
    if len(codes) != 2:
        raise ValueError(f"{where}: `çift` · `açı` satırı okunamadı: {meta!r}")
    key = pair_key(codes[0])
    aspect = codes[1].strip()
    if aspect not in ASPECT_TYPES:
        raise ValueError(f"{where}: bilinmeyen açı türü {aspect!r}")

    short = lines[short_idx][2:].strip()
    body = lines[short_idx + 1:]
    while body and body[-1].strip() in ("", "---"):
        body.pop()
    detailed = "\n".join(body).strip()

    headers = [l for l in body if l.startswith("**") and l.endswith("**")]
    category = headers[0].strip("*").strip() if headers else None
    strengths = [l.lstrip("•").strip() for l in section_after(body, "Olumlu Etkiler")]
    challenges = [l.lstrip("•").strip() for l in section_after(body, "Zorlayıcı Etkiler")]
    keyword_lines = section_after(body, "Anahtar Kelimeler")
    keywords = [k.strip() for k in keyword_lines[0].split("·")] if keyword_lines else []
    advice = " ".join(section_after(body, "Tavsiye")).strip()

    missing = [n for n, v in [("kategori", category), ("olumlu etkiler", strengths),
                              ("zorlayıcı etkiler", challenges), ("anahtar kelimeler", keywords),
                              ("tavsiye", advice)] if not v]
    if missing:
        raise ValueError(f"{where}: eksik bölüm(ler): {', '.join(missing)}")

    return key, aspect, {
        "title": title,
        "short": short,
        "detailed": detailed,
        "strengths": strengths,
        "challenges": challenges,
        "advice": advice,
        "category": category,
        "keywords": keywords,
    }


def parse_file(path: Path) -> list[tuple[str, str, dict]]:
    text = path.read_text(encoding="utf-8")
    blocks = re.split(r"^## ", text, flags=re.M)[1:]  # ilk parça dosya başlığı
    return [parse_entry("## " + b, path.name) for b in blocks]


def main() -> int:
    args = [a for a in sys.argv[1:] if a != "--dry-run"]
    dry_run = "--dry-run" in sys.argv
    if not args:
        print(__doc__)
        return 1

    data = json.loads(ASPECTS.read_text(encoding="utf-8"))
    replaced = added = 0
    seen: set[tuple[str, str]] = set()
    for arg in args:
        path = Path(arg).expanduser()
        entries = parse_file(path)
        for key, aspect, entry in entries:
            if (key, aspect) in seen:
                raise ValueError(f"{path.name}: {key}/{aspect} birden fazla kez geçiyor")
            seen.add((key, aspect))
            if aspect in data.get(key, {}):
                replaced += 1
            else:
                added += 1
            data.setdefault(key, {})[aspect] = entry
        print(f"  ✓ {path.name:32s} {len(entries):>3} kayıt")

    print(f"\n{replaced} kayıt güncellendi, {added} kayıt eklendi.")
    if dry_run:
        print("(--dry-run: aspects.json yazılmadı)")
        return 0
    ASPECTS.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"→ {ASPECTS.relative_to(ROOT)} yazıldı")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ValueError as e:
        print(f"HATA: {e}", file=sys.stderr)
        sys.exit(2)
