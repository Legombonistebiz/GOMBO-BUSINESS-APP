#!/usr/bin/env python3
"""Met à jour pronostics.json : score final + ✅ / ❌ dans le champ "cote" quand un match est terminé."""
import json, re, sys, unicodedata, urllib.request, datetime as dt

FICHIER = sys.argv[1] if len(sys.argv) > 1 else "pronostics.json"
MOIS = {"janvier":1,"fevrier":2,"mars":3,"avril":4,"mai":5,"juin":6,"juillet":7,"aout":8,
        "septembre":9,"octobre":10,"novembre":11,"decembre":12}
VIDES = {"fc","cf","sc","ac","as","afc","the","de","la","le","el","club","real","sporting","united","city"}

def norm(t):
    t = unicodedata.normalize("NFD", t.lower())
    return re.sub(r"[^a-z0-9 ]", " ", "".join(c for c in t if unicodedata.category(c) != "Mn"))

def jetons(t): return {x for x in norm(t).split() if x not in VIDES and len(x) > 1}
def meme(a, b):
    A, B = jetons(a), jetons(b)
    return bool(A & B) or norm(a).strip() == norm(b).strip()

def debut(texte):
    m = re.search(r"(\d{1,2})\s+([A-Za-zéûè]+)\s+(\d{4})\s*-\s*(\d{1,2}):(\d{2})", texte or "")
    if not m: return None
    mois = MOIS.get(norm(m.group(2)).strip())
    if not mois: return None
    return dt.datetime(int(m.group(3)), mois, int(m.group(1)), int(m.group(4)), int(m.group(5)), tzinfo=dt.timezone.utc)

def partie(p, d, e):
    p = re.sub(r"\(.*?\)", "", p.lower()).strip(); t = d + e
    m = re.match(r"^(?:over|plus de)\s*([0-9]+(?:[.,][0-9]+)?)", p)
    if m: return t > float(m.group(1).replace(",", "."))
    m = re.match(r"^(?:under|moins de)\s*([0-9]+(?:[.,][0-9]+)?)", p)
    if m: return t < float(m.group(1).replace(",", "."))
    if p.startswith("btts") or "les deux équipes marquent" in p or "les deux equipes marquent" in p:
        oui = d > 0 and e > 0
        return (not oui) if ("non" in p or p.endswith(" no")) else oui
    return {"v1": d > e, "1": d > e, "v2": e > d, "2": e > d, "x": d == e, "nul": d == e, "match nul": d == e,
            "1x": d >= e, "v1x": d >= e, "x2": e >= d, "vx2": e >= d, "12": d != e, "v12": d != e}.get(p)

def evaluer(choix, d, e):
    inconnu = False
    for p in [x.strip() for x in choix.lower().split("+") if x.strip()]:
        r = partie(p, d, e)
        if r is False: return False
        if r is None: inconnu = True
    return None if inconnu else True

def espn(jour):
    url = "https://site.api.espn.com/apis/site/v2/sports/soccer/all/scoreboard?limit=500&dates=" + jour.strftime("%Y%m%d")
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"}), timeout=20) as r:
            return json.load(r).get("events", [])
    except Exception as ex:
        print("ESPN indisponible", jour, ex); return []

def trouver(equipes, d0):
    duo = re.split(r"\s+(?:vs\.?|v|-|–)\s+", equipes, maxsplit=1, flags=re.I)
    if len(duo) != 2: return None
    for dec in (0, -1, 1):
        for ev in espn(d0 + dt.timedelta(days=dec)):
            comp = (ev.get("competitions") or [{}])[0]
            cs = comp.get("competitors") or []
            if len(cs) != 2 or not comp.get("status", {}).get("type", {}).get("completed"): continue
            noms = {c.get("homeAway"): (c.get("team") or {}).get("displayName", "") for c in cs}
            sc = {c.get("homeAway"): int(c.get("score") or 0) for c in cs}
            if meme(duo[0], noms.get("home", "")) and meme(duo[1], noms.get("away", "")): return sc["home"], sc["away"]
            if meme(duo[0], noms.get("away", "")) and meme(duo[1], noms.get("home", "")): return sc["away"], sc["home"]
    return None

def main():
    with open(FICHIER, encoding="utf-8") as f: data = json.load(f)
    now = dt.datetime.now(dt.timezone.utc); change = False
    for o in data:
        cote = o.get("cote", "") or ""
        if "✅" in cote or "❌" in cote: continue
        d0 = debut(o.get("dateEtHeure", ""))
        if not d0 or now < d0 + dt.timedelta(minutes=100) or now > d0 + dt.timedelta(days=3): continue
        r = trouver(o.get("equipes", ""), d0)
        if not r: continue
        v = evaluer(o.get("pronosticChoisi", ""), *r)
        o["score"] = f"{r[0]} - {r[1]}"
        if v is not None: o["cote"] = (cote + " " + ("✅" if v else "❌")).strip()
        change = True; print(o.get("equipes"), o["score"], v)
    if change:
        with open(FICHIER, "w", encoding="utf-8") as f: json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__": main()
  
