#!/usr/bin/env python3
"""Synastry ve Composite açı yorumlarını kanonik kompozisyonla üretir.

Bu yorumlar uygulamada Swift motorları tarafından çalışma zamanında üretilir
(SynastryInterpreter / ChartAspectInterpreter). Bu script, aynı kanonik
tablolardan TÜM kombinasyonları önceden üretip statik JSON'a yazar; tek amaç
yorum gezgininde (interpretations.html) görünür/aranabilir olmaları.

⚠️ KAYNAK SENKRONU: Aşağıdaki tablolar Swift motorlarının birebir kopyasıdır.
Swift'te metin değişirse BURAYI da güncelle (yoksa gezgin eski metni gösterir):
  - SynastryInterpreter.swift   → SYN_THEME, SYN_CLAUSE, opener
  - ChartAspectInterpreter.swift → COMP_THEME, COMP_CLAUSE, opener

Çıktı: synastry_aspects.json, composite_aspects.json (aspects.json formatı:
{ "p1_p2": { "square": {title, short, detailed}, ... } }).
"""
import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "AstroApp/Core/Interpretation/Data"

# (identifier, başlık eki, doğa) — yalnızca 5 majör açı (motorlarla aynı)
ASPECTS = [
    ("conjunction", "Kavuşumu", "notr"),
    ("sextile", "Sekstili", "harmonik"),
    ("square", "Karesi", "zorlayici"),
    ("trine", "Üçgeni", "harmonik"),
    ("opposition", "Karşıtlığı", "zorlayici"),
]

NAME = {
    "sun": "Güneş", "moon": "Ay", "mercury": "Merkür", "venus": "Venüs", "mars": "Mars",
    "jupiter": "Jüpiter", "saturn": "Satürn", "uranus": "Uranüs", "neptune": "Neptün",
    "pluto": "Plüton", "asc": "Yükselen", "mc": "MC",
}

# ───────── Synastry (SynastryInterpreter.swift kopyası) ─────────
SYN_PLANETS = ["sun", "moon", "mercury", "venus", "mars",
               "jupiter", "saturn", "uranus", "neptune", "pluto"]
SYN_THEME = {
    "sun": "kimlik ve ego ifadesi",
    "moon": "duygusal ihtiyaçlar ve yakınlık",
    "mercury": "iletişim ve fikir alışverişi",
    "venus": "sevgi, çekim ve zevkler",
    "mars": "tutku, arzu ve enerji",
    "jupiter": "büyüme, iyimserlik ve özgürlük arzusu",
    "saturn": "bağlılık, sorumluluk ve istikrar",
    "uranus": "heyecan, özgürlük ve beklenmediklik",
    "neptune": "romantik idealler ve ruhsal bağ",
    "pluto": "yoğunluk, güç ve dönüşüm",
}
SYN_CLAUSE = {
    "harmonik": "uyumlu ve destekleyici biçimde akıyor; ilişkide doğal bir uyum kaynağı.",
    "zorlayici": "güçlü bir çekim yaratıyor ama sürtüşme ve gerilim de getirebilir; farkındalıkla büyüme fırsatına dönüşür.",
    "notr": "yoğun biçimde birleşiyor; bu tema ilişkide çok belirgin ve baskın.",
}

# ───────── Composite (ChartAspectInterpreter.swift kopyası) ─────────
COMP_POINTS = ["sun", "moon", "mercury", "venus", "mars", "jupiter",
               "saturn", "uranus", "neptune", "pluto", "asc", "mc"]
COMP_THEME = {
    "sun": "kimlik ve irade",
    "moon": "duygular ve ihtiyaçlar",
    "mercury": "iletişim ve düşünce",
    "venus": "sevgi ve uyum",
    "mars": "eylem ve enerji",
    "jupiter": "büyüme ve fırsat",
    "saturn": "sorumluluk ve disiplin",
    "uranus": "değişim ve özgürlük",
    "neptune": "hayal ve sezgi",
    "pluto": "dönüşüm ve güç",
    "asc": "dış görünüş ve hayata yaklaşım",
    "mc": "kariyer ve yaşam hedefleri",
}
COMP_CLAUSE = {
    "harmonik": "uyumlu bir akış var; bu iki alan birbirini destekliyor.",
    "zorlayici": "gerilim var; bu iki alan denge ve bilinçli çaba istiyor.",
    "notr": "güçlü bir birleşme var; bu temalar belirgin biçimde öne çıkıyor.",
}


def build(points, theme, clause, opener_fmt, detailed_note, include_self):
    """points üzerindeki tüm çiftler × majör açılar için yorum üretir.

    include_self=True (synastry): iki AYRI kişinin aynı gezegeni açı yapabilir
        (Güneş-Güneş gibi) → kendisiyle çift dahil.
    include_self=False (composite): tek haritanın iç açısı; bir nokta kendisiyle
        açı yapamaz → kendisiyle çift hariç.
    """
    out = {}
    for i, p1 in enumerate(points):
        start = i if include_self else i + 1
        for p2 in points[start:]:
            entry = {}
            for asp, asp_tr, nature in ASPECTS:
                short = opener_fmt.format(t1=theme[p1], t2=theme[p2], clause=clause[nature])
                entry[asp] = {
                    "title": f"{NAME[p1]} - {NAME[p2]} {asp_tr}",
                    "short": short,
                    "detailed": f"{short} {detailed_note}",
                }
            out[f"{p1}_{p2}"] = entry
    return out


def main():
    syn = build(
        SYN_PLANETS, SYN_THEME, SYN_CLAUSE,
        "İki kişi arasında {t1} ile {t2} {clause}",
        "(Synastry: iki kişinin doğum haritası gezegenleri arasındaki etkileşim.)",
        include_self=True,
    )
    comp = build(
        COMP_POINTS, COMP_THEME, COMP_CLAUSE,
        "İlişkinizde, {t1} ile {t2} arasında {clause}",
        "(Composite: iki haritanın orta noktalarından oluşan ilişki haritasının iç açısı.)",
        include_self=False,
    )

    for name, data in [("synastry_aspects.json", syn), ("composite_aspects.json", comp)]:
        path = DATA_DIR / name
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        total = sum(len(v) for v in data.values())
        print(f"  ✓ {name:28} {len(data)} çift, {total} yorum")


if __name__ == "__main__":
    main()
