#!/usr/bin/env python3
"""
AstroApp yorum gezgini HTML üretici.

Core/Interpretation/Data/ altındaki tüm JSON dosyalarını okur ve
proje kökünde tek bir interpretations.html üretir. Yeni yorum dosyası
eklendiğinde veya mevcut dosya güncellendiğinde bu script'i çalıştır:

    python3 tools/generate_interpretations_html.py

HTML, gömülü JSON verisini istemci tarafında okur — yan dosyalara
ihtiyaç duymaz, dosyayı çift tıklayarak tarayıcıda açabilirsin.
"""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "AstroApp" / "Core" / "Interpretation" / "Data"
OUTPUT = ROOT / "interpretations.html"

# Kategori meta-bilgileri: dosya → görünür ad, ikon, kısa açıklama
CATEGORIES = [
    ("planet_house_sign.json", "Gezegenler / Ev + Burç", "🔭", "Gezegen + ev + burç üçlü kombinasyon yorumları"),
    ("house_signs.json", "Ev Burçları", "🏠", "12 evin 12 burçtaki yorumları"),
    ("aspects.json", "Açılar", "📐", "Gezegenler arası açı yorumları"),
    ("elements.json", "Elementler", "🔥", "Element baskınlık yorumları"),
    ("element_interpretations.json", "Element Yorumları", "🌊", "Element analizi metinleri"),
    ("modalities.json", "Modaliteler", "⚙️", "Öncü/Sabit/Değişken modalite yorumları"),
    ("moon_signs.json", "Ay Burçları", "🌙", "Ay burcu yorumları (kadın/erkek)"),
    ("rising_signs.json", "Yükselen Burçlar", "⬆️", "Yükselen + Güneş kombinasyonları"),
    ("tarot_cards.json", "Tarot", "🃏", "Tarot kartları (78 deste)"),
    ("katina_cards.json", "Katina", "💌", "Katina aşk falı kartları"),
    ("rune_cards.json", "Rünler", "ᚠ", "Rün kartları"),
    ("god_cards.json", "Tanrı Kartları", "⚡", "Mitolojik tanrı kartları"),
]


def load_data() -> dict:
    """Tüm JSON dosyalarını oku; dosya yoksa boş kayıt geçer."""
    bundle = {}
    for filename, *_ in CATEGORIES:
        path = DATA_DIR / filename
        if not path.exists():
            bundle[filename] = None
            continue
        with path.open("r", encoding="utf-8") as fp:
            bundle[filename] = json.load(fp)
    return bundle


HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AstroApp — Yorum Gezgini</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0}
  :root{
    --bg:#0a0613;
    --bg-2:#120a24;
    --panel:#160b2c;
    --panel-2:#1c1138;
    --border:rgba(255,255,255,0.08);
    --border-hi:rgba(196,181,253,0.35);
    --text:#ece9f7;
    --muted:rgba(236,233,247,0.55);
    --dim:rgba(236,233,247,0.32);
    --accent:#c4b5fd;
    --accent-2:#a78bfa;
    --gold:#fbbf24;
    --pink:#f9a8d4;
  }
  html,body{height:100%}
  body{
    font-family:-apple-system,BlinkMacSystemFont,'SF Pro Text','Segoe UI',system-ui,sans-serif;
    background:radial-gradient(1200px 800px at 80% -10%,rgba(124,58,237,0.18),transparent 60%),
               radial-gradient(900px 600px at -10% 100%,rgba(236,72,153,0.12),transparent 60%),
               var(--bg);
    color:var(--text);
    line-height:1.55;
    -webkit-font-smoothing:antialiased;
    overflow:hidden;
  }

  .layout{display:grid;grid-template-columns:280px 1fr;height:100vh}

  /* SIDEBAR */
  aside{
    background:linear-gradient(180deg,var(--bg-2) 0%,var(--bg) 100%);
    border-right:1px solid var(--border);
    display:flex;flex-direction:column;
    overflow:hidden;
  }
  .brand{padding:18px 20px 14px;border-bottom:1px solid var(--border)}
  .brand .logo{font-size:11px;letter-spacing:0.18em;color:var(--dim);text-transform:uppercase}
  .brand h1{font-size:18px;font-weight:600;color:var(--text);margin-top:4px;letter-spacing:-0.01em}
  .brand .sub{font-size:11px;color:var(--muted);margin-top:4px}

  .toolbar{padding:12px 14px;display:flex;flex-direction:column;gap:8px;border-bottom:1px solid var(--border)}
  .search{
    background:rgba(255,255,255,0.04);border:1px solid var(--border);
    border-radius:10px;padding:9px 11px;color:var(--text);font-size:13px;
    width:100%;outline:none;transition:border-color .15s;
  }
  .search::placeholder{color:var(--dim)}
  .search:focus{border-color:var(--border-hi)}

  .lang-toggle{display:flex;background:rgba(255,255,255,0.03);border:1px solid var(--border);border-radius:8px;padding:2px}
  .lang-toggle button{
    flex:1;background:transparent;border:none;color:var(--muted);
    padding:5px 10px;border-radius:6px;cursor:pointer;font-size:11px;letter-spacing:0.06em;
    font-family:inherit;
  }
  .lang-toggle button.active{background:rgba(196,181,253,0.18);color:var(--accent)}

  .cats{flex:1;overflow-y:auto;padding:8px 8px 16px}
  .cats::-webkit-scrollbar{width:6px}
  .cats::-webkit-scrollbar-thumb{background:rgba(255,255,255,0.08);border-radius:3px}
  .cat{
    display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:8px;
    cursor:pointer;color:var(--muted);font-size:13px;margin-bottom:2px;transition:all .12s;
  }
  .cat:hover{background:rgba(255,255,255,0.04);color:var(--text)}
  .cat.active{background:linear-gradient(90deg,rgba(167,139,250,0.18),rgba(167,139,250,0.04));color:var(--text)}
  .cat .ic{font-size:16px;width:22px;text-align:center;flex-shrink:0}
  .cat .nm{flex:1;font-weight:500}
  .cat .ct{font-size:10px;color:var(--dim);background:rgba(255,255,255,0.04);padding:2px 7px;border-radius:10px}

  .footer{padding:10px 16px;border-top:1px solid var(--border);font-size:10px;color:var(--dim)}

  /* MAIN */
  main{overflow-y:auto;padding:28px 32px 60px}
  main::-webkit-scrollbar{width:8px}
  main::-webkit-scrollbar-thumb{background:rgba(255,255,255,0.08);border-radius:4px}

  .head{margin-bottom:24px}
  .head .crumb{font-size:11px;color:var(--dim);letter-spacing:0.16em;text-transform:uppercase;margin-bottom:4px}
  .head h2{font-size:24px;font-weight:600;letter-spacing:-0.01em}
  .head .desc{color:var(--muted);font-size:13px;margin-top:6px;max-width:680px}
  .head .meta{display:flex;gap:14px;margin-top:14px;font-size:11px;color:var(--dim)}
  .head .meta span b{color:var(--accent);font-weight:500}

  .lang-warn{
    background:linear-gradient(90deg,rgba(251,191,36,0.10),rgba(251,191,36,0.02));
    border:1px solid rgba(251,191,36,0.20);
    border-radius:10px;padding:10px 14px;color:#fde68a;font-size:12px;
    margin-bottom:20px;
  }

  .grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(380px,1fr));gap:14px}
  .card{
    background:linear-gradient(180deg,var(--panel) 0%,var(--panel-2) 100%);
    border:1px solid var(--border);border-radius:14px;
    padding:18px 18px 16px;transition:border-color .15s,transform .15s;
    display:flex;flex-direction:column;gap:10px;
  }
  .card:hover{border-color:var(--border-hi)}

  .card .ttl{display:flex;align-items:baseline;gap:8px;flex-wrap:wrap}
  .card .ttl h3{font-size:15px;font-weight:600;color:var(--text);letter-spacing:-0.01em}
  .card .ttl .tag{font-size:9px;letter-spacing:0.10em;text-transform:uppercase;color:var(--dim);background:rgba(255,255,255,0.04);padding:2px 7px;border-radius:10px}
  .card .ttl .tag.acc{color:var(--accent);background:rgba(196,181,253,0.10)}
  .card .ttl .tag.pnk{color:var(--pink);background:rgba(249,168,212,0.10)}
  .card .ttl .tag.gld{color:var(--gold);background:rgba(251,191,36,0.10)}

  .card .short{color:var(--muted);font-size:12.5px;font-style:italic}

  .card details{margin-top:2px}
  .card details summary{
    cursor:pointer;list-style:none;font-size:11px;letter-spacing:0.08em;
    text-transform:uppercase;color:var(--accent);user-select:none;padding:4px 0;
  }
  .card details summary::-webkit-details-marker{display:none}
  .card details summary::before{content:'▸ ';display:inline-block;transition:transform .15s}
  .card details[open] summary::before{transform:rotate(90deg)}

  .card .body{
    color:var(--text);font-size:13px;line-height:1.65;margin-top:8px;
    white-space:pre-wrap;word-wrap:break-word;
  }
  .card .body b,.card .body strong{color:var(--accent);font-weight:600}
  .card .body em{color:var(--pink)}
  .card .body code{background:rgba(255,255,255,0.05);padding:1px 5px;border-radius:4px;font-size:12px}

  .subsec{margin-top:10px}
  .subsec h4{
    font-size:10px;letter-spacing:0.10em;text-transform:uppercase;color:var(--dim);
    margin-bottom:6px;font-weight:500;
  }
  .pillrow{display:flex;flex-wrap:wrap;gap:5px}
  .pill{
    font-size:11px;background:rgba(255,255,255,0.05);border:1px solid var(--border);
    color:var(--muted);padding:3px 8px;border-radius:12px;
  }
  .pill.pos{color:#a7f3d0;background:rgba(16,185,129,0.08);border-color:rgba(16,185,129,0.2)}
  .pill.neg{color:#fda4af;background:rgba(244,63,94,0.08);border-color:rgba(244,63,94,0.2)}

  .advice{
    background:rgba(196,181,253,0.06);border-left:2px solid var(--accent);
    padding:8px 12px;border-radius:0 8px 8px 0;font-size:12.5px;color:var(--text);
  }
  .advice b{color:var(--accent)}

  .empty{padding:60px 20px;text-align:center;color:var(--dim);font-size:13px}

  /* TABS for tarot card descriptions */
  .tabs{display:flex;gap:4px;flex-wrap:wrap;margin-top:2px}
  .tab{
    background:rgba(255,255,255,0.04);border:1px solid var(--border);
    color:var(--muted);font-size:10px;letter-spacing:0.06em;text-transform:uppercase;
    padding:4px 10px;border-radius:6px;cursor:pointer;font-family:inherit;
  }
  .tab.active{background:rgba(196,181,253,0.15);color:var(--accent);border-color:var(--border-hi)}

  /* Filter pills inside category (e.g. gender for moon signs) */
  .filters{display:flex;gap:6px;margin-bottom:14px;flex-wrap:wrap}
  .filters .fp{
    background:rgba(255,255,255,0.04);border:1px solid var(--border);
    color:var(--muted);font-size:11px;padding:5px 11px;border-radius:14px;cursor:pointer;
    font-family:inherit;
  }
  .filters .fp.active{background:rgba(196,181,253,0.15);color:var(--accent);border-color:var(--border-hi)}

  /* Kapsam matrisi */
  .cov-legend{display:flex;align-items:center;gap:6px;font-size:11px;color:var(--muted);margin-bottom:18px}
  .cov-block{margin-bottom:22px}
  .cov-title{display:flex;align-items:baseline;gap:10px;margin-bottom:6px}
  .cov-title b{font-size:14px;color:var(--text)}
  .cov-stat{font-size:11px;color:var(--dim)}
  .cov-grid{display:inline-block;background:rgba(255,255,255,0.02);border:1px solid var(--border);border-radius:10px;padding:8px}
  .cov-row{display:flex;align-items:center}
  .cov-rh{width:46px;font-size:10px;color:var(--dim);text-align:right;padding-right:8px;flex-shrink:0}
  .cov-ch{width:22px;text-align:center;font-size:12px;color:var(--muted)}
  .cov-cell{width:22px;height:18px;border-radius:3px;background:rgba(255,255,255,0.05);margin:1px;display:inline-block;flex-shrink:0;border:1px solid transparent}
  .cov-cell.on{background:var(--accent-2);border-color:var(--accent)}
</style>
</head>
<body>
<div class="layout">
  <aside>
    <div class="brand">
      <div class="logo">AstroApp</div>
      <h1>Yorum Gezgini</h1>
      <div class="sub">Tüm yorumlar tek yerde</div>
    </div>
    <div class="toolbar">
      <input id="search" class="search" placeholder="Yorumlarda ara…" autocomplete="off">
      <div class="lang-toggle">
        <button data-lang="tr" class="active">TR</button>
        <button data-lang="en">EN</button>
      </div>
    </div>
    <div id="cats" class="cats"></div>
    <div class="footer" id="footer"></div>
  </aside>
  <main id="main"></main>
</div>

<script id="data" type="application/json">__DATA_JSON__</script>
<script id="catmeta" type="application/json">__CATMETA_JSON__</script>

<script>
const DATA = JSON.parse(document.getElementById('data').textContent);
const META = JSON.parse(document.getElementById('catmeta').textContent);
let currentCat = META[0].file;
let currentLang = 'tr';
let searchQuery = '';
let activeFilter = null; // for sub-filters like gender

// ---------- Helpers ----------
function escapeHtml(s){
  if(s == null) return '';
  return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
}
function md(text){
  // Mini markdown: **bold**, *em*, line breaks, keep emojis as-is
  let s = escapeHtml(text);
  s = s.replace(/\*\*([^*\n]+?)\*\*/g, '<b>$1</b>');
  s = s.replace(/(?<!\*)\*([^*\n]+?)\*(?!\*)/g, '<em>$1</em>');
  return s;
}
// Üst seviye kayıt mı, alt kategoriler mi olduğunu içerikten anlar
function isLeafRecord(v){
  if(!v || typeof v !== 'object' || Array.isArray(v)) return true;
  // Title/short/detailed gibi leaf alanları varsa leaf'tir
  const leafKeys = ['title','short','detailed','description','strengths','challenges','advice'];
  return leafKeys.some(k => k in v);
}
function countItems(file, data){
  if(file === '__coverage__') return 0;  // sayma sekmesi, yorum sayısına katılmaz
  if(!data) return 0;
  if(Array.isArray(data)) return data.length;
  let n = 0;
  for(const k in data){
    const v = data[k];
    if(isLeafRecord(v)) n++;
    else for(const k2 in v) n++;
  }
  return n;
}

// ---------- Sidebar ----------
function renderCats(){
  const wrap = document.getElementById('cats');
  wrap.innerHTML = META.map(m => {
    const active = m.file === currentCat ? 'active' : '';
    const ctHtml = m.file === '__coverage__' ? '' : `<div class="ct">${countItems(m.file, DATA[m.file])}</div>`;
    return `<div class="cat ${active}" data-file="${m.file}">
      <div class="ic">${m.icon}</div>
      <div class="nm">${escapeHtml(m.name)}</div>
      ${ctHtml}
    </div>`;
  }).join('');
  wrap.querySelectorAll('.cat').forEach(el => {
    el.addEventListener('click', () => { currentCat = el.dataset.file; activeFilter = null; renderCats(); renderMain(); });
  });
  // Footer summary
  const total = META.reduce((a,m) => a + countItems(m.file, DATA[m.file]), 0);
  document.getElementById('footer').textContent = `Toplam ${total} yorum • ${META.length} kategori`;
}

// ---------- Card renderers per category type ----------
function flatList(file){
  // Returns array of {title, short, detailed, strengths, challenges, advice, tags, body, extra}
  const d = DATA[file];
  if(!d) return [];
  const out = [];

  if(file === 'aspects.json'){
    for(const pair in d){
      for(const asp in d[pair]){
        const v = d[pair][asp];
        out.push({
          title: v.title || `${pair} / ${asp}`,
          tags: [pair.replace('_',' / '), asp],
          short: v.short, detailed: v.detailed,
          strengths: v.strengths, challenges: v.challenges, advice: v.advice
        });
      }
    }
  } else if(file === 'elements.json' || file === 'modalities.json'){
    for(const k in d){
      const v = d[k];
      out.push({
        title: v.title || k, tags: [k],
        short: v.short, detailed: v.detailed,
        strengths: v.strengths, challenges: v.challenges, advice: v.advice
      });
    }
  } else if(file === 'element_interpretations.json'){
    for(const v of d){
      out.push({
        title: v.name || v.key,
        tags: [v.key],
        short: v.description,
        sections: [
          { h: 'Az / Eksik', body: v.less },
          { h: 'Çok / Baskın', body: v.more },
        ].filter(s => s.body)
      });
    }
  } else if(file === 'moon_signs.json'){
    for(const v of d){
      out.push({
        title: v.name,
        tags: [v.element, v.gender === 'men' ? 'Erkek' : 'Kadın'],
        filterKey: v.gender,
        body: v.description
      });
    }
  } else if(file === 'rising_signs.json'){
    for(const v of d){
      out.push({
        title: v.name,
        tags: [`Yük: ${v.risingElement}`, `Gün: ${v.sunElement}`],
        filterKey: v.risingKey,
        body: v.description
      });
    }
  } else if(file === 'house_signs.json'){
    for(const v of d){
      out.push({
        title: v.name,
        tags: [`Ev ${v.houseId}`, v.sign],
        filterKey: String(v.houseId),
        body: v.description
      });
    }
  } else if(file === 'tarot_cards.json'){
    for(const v of d){
      out.push({
        title: `${v.image || ''} ${v.name}`.trim(),
        tags: [v.arcana, `#${v.id}`],
        tabbed: v.descriptions,
        filterKey: v.arcana
      });
    }
  } else if(file === 'katina_cards.json'){
    for(const v of d){
      out.push({ title: `${v.name} (#${v.id})`, body: v.description });
    }
  } else if(file === 'rune_cards.json'){
    for(const v of d){
      out.push({ title: `${v.symbol || ''} ${v.name}`.trim(), tags: [`#${v.id}`], body: v.description });
    }
  } else if(file === 'god_cards.json'){
    for(const v of d){
      out.push({ title: `${v.name} (#${v.id})`, body: v.description });
    }
  } else if(file === 'planet_house_sign.json'){
    for(const v of d){
      out.push({
        title: `${v.icon || ''} ${v.title}`.trim(),
        tags: [v.planetName, `${v.houseId}. Ev`, v.signName],
        filterKey: v.planet,
        body: v.description
      });
    }
  }
  return out;
}

function renderCard(item){
  const tags = (item.tags||[]).map((t,i)=>{
    const cls = ['','acc','pnk','gld'][i % 4];
    return `<span class="tag ${cls}">${escapeHtml(t)}</span>`;
  }).join('');

  let parts = [`<div class="ttl"><h3>${escapeHtml(item.title)}</h3>${tags}</div>`];

  if(item.short) parts.push(`<div class="short">${md(item.short)}</div>`);

  if(item.detailed){
    parts.push(`<details><summary>Detaylı yorum</summary><div class="body">${md(item.detailed)}</div></details>`);
  }
  if(item.body){
    parts.push(`<details open><summary>Tam metin</summary><div class="body">${md(item.body)}</div></details>`);
  }
  if(item.sections){
    for(const sec of item.sections){
      parts.push(`<details><summary>${escapeHtml(sec.h)}</summary><div class="body">${md(sec.body)}</div></details>`);
    }
  }
  if(item.tabbed){
    const keys = Object.keys(item.tabbed);
    const tabs = keys.map((k,i)=>`<button class="tab ${i===0?'active':''}" data-k="${k}">${escapeHtml(k)}</button>`).join('');
    const bodies = keys.map((k,i)=>`<div class="body" data-bk="${k}" style="display:${i===0?'block':'none'}">${md(item.tabbed[k])}</div>`).join('');
    parts.push(`<div class="tabs">${tabs}</div>${bodies}`);
  }
  if(item.strengths && item.strengths.length){
    parts.push(`<div class="subsec"><h4>Güçlü Yönler</h4><div class="pillrow">${item.strengths.map(s=>`<span class="pill pos">${escapeHtml(s)}</span>`).join('')}</div></div>`);
  }
  if(item.challenges && item.challenges.length){
    parts.push(`<div class="subsec"><h4>Zorluklar</h4><div class="pillrow">${item.challenges.map(s=>`<span class="pill neg">${escapeHtml(s)}</span>`).join('')}</div></div>`);
  }
  if(item.advice){
    parts.push(`<div class="advice"><b>Tavsiye:</b> ${md(item.advice)}</div>`);
  }

  return `<div class="card">${parts.join('')}</div>`;
}

function buildFilters(items, file){
  // Show sub-filters when category benefits from them
  let opts = null, label = '';
  if(file === 'moon_signs.json'){
    opts = [['men','Erkek'],['women','Kadın']]; label = 'Cinsiyet';
  } else if(file === 'tarot_cards.json'){
    opts = [['major','Major Arcana'],['minor','Minor Arcana']]; label = 'Arcana';
  } else if(file === 'house_signs.json'){
    const ids = [...new Set(items.map(i=>i.filterKey))].sort((a,b)=>+a-+b);
    opts = ids.map(i => [i, `Ev ${i}`]); label = 'Ev';
  } else if(file === 'planet_house_sign.json'){
    // Gezegen bazlı filtre — her gezegenin görünür adıyla
    const seen = new Map();
    for(const it of items){ if(!seen.has(it.filterKey)) seen.set(it.filterKey, (it.tags||[])[0] || it.filterKey); }
    opts = [...seen.entries()]; label = 'Gezegen';
  }
  if(!opts) return '';
  const pills = opts.map(([k,n]) =>
    `<button class="fp ${activeFilter===k?'active':''}" data-k="${k}">${escapeHtml(n)}</button>`
  ).join('');
  const all = `<button class="fp ${!activeFilter?'active':''}" data-k="">Tümü</button>`;
  return `<div class="filters" data-role="filters">${all}${pills}</div>`;
}

// Kapsam matrisi için obje sırası ve TR adları
const COV_PLANETS = [
  ['sun','Güneş'],['moon','Ay'],['mercury','Merkür'],['venus','Venüs'],['mars','Mars'],
  ['jupiter','Jüpiter'],['saturn','Satürn'],['uranus','Uranüs'],['neptune','Neptün'],
  ['pluto','Plüton'],['north_node','Kuzey Düğüm'],['chiron','Chiron'],['lilith','Lilith'],
  ['part_of_fortune','Talih Noktası'],['ceres','Ceres'],['pallas','Pallas'],['juno','Juno'],['vesta','Vesta']
];
const COV_SIGNS = ['Aries','Taurus','Gemini','Cancer','Leo','Virgo','Libra','Scorpio','Sagittarius','Capricorn','Aquarius','Pisces'];
const COV_SIGNS_TR = ['Koç','Boğa','İkizler','Yengeç','Aslan','Başak','Terazi','Akrep','Yay','Oğlak','Kova','Balık'];
const COV_SIGN_GLYPH = ['♈︎','♉︎','♊︎','♋︎','♌︎','♍︎','♎︎','♏︎','♐︎','♑︎','♒︎','♓︎'];

function renderCoverage(){
  const main = document.getElementById('main');
  const data = DATA['planet_house_sign.json'] || [];
  const have = new Set(data.map(e => `${e.planet}|${e.houseId}|${e.sign}`));
  const TOTAL = COV_PLANETS.length * 12 * 12;
  let filled = 0;
  for(const [pk] of COV_PLANETS) for(let h=1;h<=12;h++) for(const s of COV_SIGNS) if(have.has(`${pk}|${h}|${s}`)) filled++;

  const q = searchQuery.trim().toLowerCase();

  let grids = '';
  for(const [pk, pn] of COV_PLANETS){
    if(q && !pn.toLowerCase().includes(q)) continue;
    let cnt = 0;
    let rows = '';
    // başlık satırı (burç glyph'leri)
    let head = '<div class="cov-row"><div class="cov-rh"></div>' +
      COV_SIGNS.map((s,i)=>`<div class="cov-ch" title="${COV_SIGNS_TR[i]}">${COV_SIGN_GLYPH[i]}</div>`).join('') + '</div>';
    for(let h=1;h<=12;h++){
      let cells = '';
      for(let si=0; si<12; si++){
        const on = have.has(`${pk}|${h}|${COV_SIGNS[si]}`);
        if(on) cnt++;
        cells += `<div class="cov-cell ${on?'on':''}" title="${pn} ${h}. Ev ${COV_SIGNS_TR[si]}${on?' ✓':' (eksik)'}"></div>`;
      }
      rows += `<div class="cov-row"><div class="cov-rh">${h}. ev</div>${cells}</div>`;
    }
    const pct = Math.round(cnt/144*100);
    grids += `<div class="cov-block">
      <div class="cov-title"><b>${escapeHtml(pn)}</b><span class="cov-stat">${cnt}/144 · %${pct}</span></div>
      <div class="cov-grid">${head}${rows}</div>
    </div>`;
  }

  main.innerHTML = `
    <div class="head">
      <div class="crumb">📊 Kapsam Matrisi</div>
      <h2>Kapsam Matrisi</h2>
      <div class="desc">Her obje için 12 ev (satır) × 12 burç (sütun). Dolu hücre = yorum mevcut. Üzerine gelince hangi kombinasyon olduğu görünür.</div>
      <div class="meta">
        <span>Toplam <b>${filled}</b> / ${TOTAL} kombinasyon dolu</span>
        <span><b>${TOTAL - filled}</b> eksik</span>
      </div>
    </div>
    <div class="cov-legend">
      <span class="cov-cell on"></span> dolu
      <span class="cov-cell" style="margin-left:14px"></span> eksik
    </div>
    ${grids || '<div class="empty">Eşleşen obje yok.</div>'}
  `;
}

function renderMain(){
  if(currentCat === '__coverage__'){ renderCoverage(); return; }
  const meta = META.find(m => m.file === currentCat);
  const data = DATA[currentCat];
  const main = document.getElementById('main');

  if(!data){
    main.innerHTML = `<div class="head"><div class="crumb">${meta.icon}</div><h2>${escapeHtml(meta.name)}</h2></div><div class="empty">Bu kategori için henüz veri bulunamadı.</div>`;
    return;
  }

  const items = flatList(currentCat);
  const total = items.length;
  const q = searchQuery.trim().toLowerCase();

  let filtered = items;
  if(activeFilter) filtered = filtered.filter(i => i.filterKey === activeFilter);
  if(q){
    filtered = filtered.filter(i => {
      const blob = JSON.stringify(i).toLowerCase();
      return blob.includes(q);
    });
  }

  const langWarn = currentLang === 'en'
    ? `<div class="lang-warn">İngilizce yorum çevirileri henüz mevcut değil — tüm metinler şu an Türkçe. Lokalizasyon eklendiğinde bu görünüm çalışacak.</div>`
    : '';

  const filters = buildFilters(items, currentCat);

  main.innerHTML = `
    <div class="head">
      <div class="crumb">${meta.icon} ${escapeHtml(meta.name)}</div>
      <h2>${escapeHtml(meta.name)}</h2>
      <div class="desc">${escapeHtml(meta.desc)}</div>
      <div class="meta">
        <span><b>${filtered.length}</b> / ${total} kayıt gösteriliyor</span>
        ${q ? `<span>Arama: <b>"${escapeHtml(searchQuery)}"</b></span>` : ''}
        <span>Dosya: <b>${escapeHtml(currentCat)}</b></span>
      </div>
    </div>
    ${langWarn}
    ${filters}
    ${filtered.length === 0
      ? `<div class="empty">Eşleşen yorum bulunamadı.</div>`
      : `<div class="grid">${filtered.map(renderCard).join('')}</div>`}
  `;

  // Hook tabs
  main.querySelectorAll('.tabs').forEach(tabs => {
    const card = tabs.closest('.card');
    tabs.querySelectorAll('.tab').forEach(btn => {
      btn.addEventListener('click', () => {
        tabs.querySelectorAll('.tab').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        card.querySelectorAll('[data-bk]').forEach(b => b.style.display = 'none');
        const target = card.querySelector(`[data-bk="${btn.dataset.k}"]`);
        if(target) target.style.display = 'block';
      });
    });
  });

  // Hook filter pills
  const filterBar = main.querySelector('[data-role="filters"]');
  if(filterBar){
    filterBar.querySelectorAll('.fp').forEach(btn => {
      btn.addEventListener('click', () => {
        activeFilter = btn.dataset.k || null;
        renderMain();
      });
    });
  }
}

// ---------- Events ----------
document.getElementById('search').addEventListener('input', e => {
  searchQuery = e.target.value;
  renderMain();
});
document.querySelectorAll('.lang-toggle button').forEach(btn => {
  btn.addEventListener('click', () => {
    document.querySelectorAll('.lang-toggle button').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    currentLang = btn.dataset.lang;
    renderMain();
  });
});

renderCats();
renderMain();
</script>
</body>
</html>
"""


def main() -> None:
    bundle = load_data()
    meta = [
        {"file": f, "name": n, "icon": i, "desc": d}
        for (f, n, i, d) in CATEGORIES
    ]
    # Kapsam matrisi sekmesi — gezegen × ev × burç doluluk haritası.
    # planet_house_sign.json verisinden istemci tarafında türetilir.
    if bundle.get("planet_house_sign.json"):
        meta.insert(1, {
            "file": "__coverage__",
            "name": "Kapsam Matrisi",
            "icon": "📊",
            "desc": "Gezegen × ev × burç — hangi kombinasyonlar dolu, hangileri eksik",
        })
        bundle["__coverage__"] = "ok"  # null değil → 'veri yok' gösterme
    data_json = json.dumps(bundle, ensure_ascii=False, separators=(",", ":"))
    meta_json = json.dumps(meta, ensure_ascii=False, separators=(",", ":"))
    # Escape </script> to be safe inside <script> tag
    data_json = data_json.replace("</", "<\\/")
    meta_json = meta_json.replace("</", "<\\/")
    html = HTML_TEMPLATE.replace("__DATA_JSON__", data_json).replace("__CATMETA_JSON__", meta_json)
    OUTPUT.write_text(html, encoding="utf-8")

    total = 0
    for f, *_ in CATEGORIES:
        d = bundle.get(f)
        if d is None:
            print(f"  ⚠️  {f} bulunamadı")
            continue
        leaf_keys = {"title", "short", "detailed", "description", "strengths", "challenges", "advice"}
        def is_leaf(v):
            return not isinstance(v, dict) or any(k in v for k in leaf_keys)
        if isinstance(d, list):
            n = len(d)
        else:
            n = sum(1 if is_leaf(v) else len(v) for v in d.values())
        total += n
        print(f"  ✓ {f:32s} {n:>4} kayıt")
    print(f"\n→ {OUTPUT.relative_to(ROOT)} ({OUTPUT.stat().st_size // 1024} KB, {total} toplam yorum)")


if __name__ == "__main__":
    main()
