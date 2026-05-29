import zipfile, re, os, glob, json
from xml.etree import ElementTree as ET
NS = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"

DOCS = "/Users/devrim.bal/Desktop/docs"
OUT = "/Users/devrim.bal/Projects/astro/AstroApp/Core/Interpretation/Data/planet_house_sign.json"

# dosya numarası -> (planet_key, görünür ad, ikon, sıra)
PLANET_BY_NUM = {
    1:  ("sun",        "Güneş",            "☀️"),
    2:  ("moon",       "Ay",               "🌙"),
    3:  ("mercury",    "Merkür",           "🧠"),
    4:  ("venus",      "Venüs",            "💕"),
    5:  ("mars",       "Mars",             "🔥"),
    6:  ("jupiter",    "Jüpiter",          "🌌"),
    7:  ("saturn",     "Satürn",           "🪐"),
    8:  ("uranus",     "Uranüs",           "⚡️"),
    9:  ("neptune",    "Neptün",           "🌊"),
    10: ("pluto",      "Plüton",           "🦂"),
    11: ("north_node", "Kuzey Ay Düğümü",  "🧭"),
    12: ("chiron",     "Chiron",           "🜁"),
    13: ("lilith",     "Lilith",           "🌑"),
    14: ("part_of_fortune", "Talih Noktası", "🍀"),
    15: ("ceres",      "Ceres",            "🌾"),
    16: ("pallas",     "Pallas",           "🛡"),
    17: ("juno",       "Juno",             "💍"),
    18: ("vesta",      "Vesta",            "🕯"),
}
PLANET_ORDER = {key: num for num, (key, _, _) in PLANET_BY_NUM.items()}

SIGN_TR_EN = {
    "Koç": "Aries", "Boğa": "Taurus", "İkizler": "Gemini", "Yengeç": "Cancer",
    "Aslan": "Leo", "Başak": "Virgo", "Terazi": "Libra", "Akrep": "Scorpio",
    "Yay": "Sagittarius", "Oğlak": "Capricorn", "Kova": "Aquarius", "Balık": "Pisces",
}

PLANET_TOKENS = ["☀️","🌙","🧠","💕","🔥","🌌","🪐","⚡️","🌊","🦂","🌑","🌾","💍","🕯","🜁","🧭","🍀","💫","🛡",
                 "Satürn","Güneş","Ay","Merkür","Venüs","Mars","Jüpiter","Uranüs","Neptün","Plüton","Chiron",
                 "Lilith","Ceres","Pallas","Juno","Vesta","Kuzey Ay Düğümü","Talih Noktası"]

hdr = re.compile(r"(\d+)\.?\s*Evde\s+([A-Za-zÇĞİÖŞÜçğıöşü]+)\s+Burcunda")

def full_text(path):
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("word/document.xml").decode("utf-8"))
    return "\n".join("".join(t.text for t in p.iter(f"{NS}t") if t.text) for p in root.iter(f"{NS}p"))

def strip_trailing_planet(s):
    s = s.rstrip()
    changed = True
    while changed:
        changed = False
        for tok in PLANET_TOKENS:
            if s.endswith(tok):
                s = s[:-len(tok)].rstrip(); changed = True
    # satır içine yapışmış madde işaretlerini ayır
    s = re.sub(r"(?<!\n)\s*•\s*", "\n• ", s)
    s = re.sub(r"\n{3,}", "\n\n", s)
    s = re.sub(r"[ \t]+\n", "\n", s)
    return s.strip()

records = {}
files = sorted(glob.glob(f"{DOCS}/*.docx"))
for f in files:
    m = re.match(r"(\d+)", os.path.basename(f))
    num = int(m.group(1)) if m else None
    if num not in PLANET_BY_NUM:
        print("⚠️ tanınmadı:", f); continue
    pkey, pname, picon = PLANET_BY_NUM[num]
    txt = full_text(f)
    ms = list(hdr.finditer(txt))
    for i, mm in enumerate(ms):
        house = int(mm.group(1))
        sign_tr = mm.group(2)
        sign_en = SIGN_TR_EN.get(sign_tr)
        if not sign_en:
            continue
        start = mm.end()
        end = ms[i+1].start() if i+1 < len(ms) else len(txt)
        content = strip_trailing_planet(txt[start:end].strip())
        if len(content) < 20:
            continue
        k = (pkey, house, sign_en)
        if k not in records or len(content) > len(records[k][1]):
            records[k] = (sign_tr, content, pname, picon)

out = []
for (pkey, house, sign_en), (sign_tr, content, pname, picon) in records.items():
    out.append({
        "planet": pkey, "planetName": pname, "icon": picon,
        "houseId": house, "sign": sign_en, "signName": sign_tr,
        "title": f"{pname} {house}. Evde {sign_tr} Burcunda",
        "description": content,
    })
out.sort(key=lambda r: (PLANET_ORDER.get(r["planet"], 99), r["houseId"], r["sign"]))

with open(OUT, "w", encoding="utf-8") as fp:
    json.dump(out, fp, ensure_ascii=False, indent=2); fp.write("\n")

print(f"Toplam {len(out)} kayıt → {OUT}")
from collections import Counter
for name, n in Counter(r["planetName"] for r in out).items():
    print(f"  {name:20s} {n}")
