---
tipus: folyamat
frissitve: 2026-10-15
---

# Fejlesztési folyamat

## A szoftverfejlesztés lépései ebben a projektben

```
 Ötlet ──► Koncepció ──► Fejlesztés ──► Tesztelés ──► Hibajavítás ──► Kiadás
  (04)       (01, ADR)     (git ág)       (05)           (06)          (tag, APK)
   ▲                                                                     │
   └─────────────────────── visszajelzés, új ötletek ◄───────────────────┘
```

1. **Ötlet** – bármi, ami eszedbe jut → [[04 Ötletek]]
2. **Koncepció** – ha egy ötletet megvalósítunk: a [[01 Specifikáció]] módosul (új / módosított FR), és ha választani kell több megoldás közül, új döntés (ADR) a `Döntések` mappában
3. **Fejlesztés** – külön git ágon
4. **Tesztelés** – automatikus tesztek + kézi tesztlista a telefonon → [[05 Tesztelés]]
5. **Hibajavítás** – hibajegy a GitHubon → javítás → újratesztelés → [[06 Hibák]]
6. **Kiadás** – verziócímke, automatikusan fordított és aláírt APK, [[CHANGELOG]]

## Verziószámozás

[Szemantikus verziózás](https://semver.org): `FŐ.AL.JAVÍTÁS`, pl. `1.2.3`

| Rész | Mikor nő | Példa |
|---|---|---|
| FŐ | Nem visszafelé kompatibilis változás (pl. új `.cetli` formátum, amit a régi app nem tud olvasni) | 1.4.2 → **2.0.0** |
| AL | Új funkció, visszafelé kompatibilis | 1.4.2 → 1.**5**.0 |
| JAVÍTÁS | Csak hibajavítás | 1.4.2 → 1.4.**3** |

A `0.x` verziók fejlesztési állapotot jelölnek; az `1.0.0` az első stabil kiadás. A Preview-k jele `x.y.z-dev.N` (N = a commitok száma).

## Git ágak

| Ág | Mire |
|---|---|
| `main` | Mindig működő, kiadható állapot. **Védett:** csak Pull Requesttel és zöld CI-vel változhat. |
| `feature/<short-name>` | Új funkció / verzió, pl. `feature/lists` |
| `fix/<issue>-<short-name>` | Hibajavítás, pl. `fix/12-merge-notes` |
| `docs/<short-name>` | Csak dokumentáció, pl. `docs/concept` |
| `release/<x.y.z>` | Kiadás előkészítése (verziószám, CHANGELOG), ha külön kell |

Menet: ág → commitok → **Pull Request** → zöld CI → *Merge* → az ág törlése → `main` frissítése → címke.

## Commit-üzenetek

[Conventional Commits](https://www.conventionalcommits.org), **angolul**, felszólító módban, kisbetűvel, pont nélkül:

| Előtag | Jelentés | Példa |
|---|---|---|
| `feat:` | új funkció | `feat: add shopping mode with strike-through` |
| `fix:` | hibajavítás | `fix: keep notes when merging duplicate items (#12)` |
| `docs:` | dokumentáció | `docs: record K-03 decision` |
| `test:` | tesztek | `test: cover name key normalisation` |
| `refactor:` | átszervezés funkcióváltozás nélkül | `refactor: split list repository` |
| `ci:` | CI / kiadási folyamat | `ci: pin NDK version` |
| `chore:` | karbantartás, beállítások | `chore: bump dependencies` |

A `(#12)` a GitHub-hibajegyre hivatkozik; a PR leírásában a `Closes #12` le is zárja.
A Claude-dal közösen készült commitok `Co-Authored-By` sort kapnak.

## Pull Request

- Cím: mint egy commit-üzenet, pl. `feat: lists and shopping mode (v0.2.0)`
- Leírás: a sablon szerint (mit, miért, hogyan tesztelve, kapcsolódó issue-k)
- Merge feltétele: zöld CI; a `main` közvetlenül nem módosítható

## Kiadás

**Menet közben (minden push egy ágra):** a CI lefuttatja az elemzést és a teszteket, aláírt APK-t fordít, és frissíti a **Preview** előzetes kiadást → telefonon kipróbálható.

**Verzió kiadása:**
1. A fejlesztési ágon a [[CHANGELOG]]-ban az `[Unreleased]` rész átnevezése a verziószámra + dátum, a `pubspec.yaml`-ban `version: x.y.z+1`
2. Pull Request → zöld CI → *Merge* → *Delete branch*
3. GitHub Desktop: `main` → *Fetch origin* / *Pull origin*
4. *History* → jobb klikk a merge commitra → *Create Tag…* → `vX.Y.Z` → *Push origin* (a címkével együtt)
5. A CI aláírt APK-t fordít, és létrehozza a GitHub Release-t a CHANGELOG adott szakaszával. Ha a címke és a `pubspec.yaml` verziója eltér, leáll.
6. [[02 Ütemterv]]: állapot 🟢, mérföldkő-napló
7. Telepítés a telefonokra, kézi teszt ([[05 Tesztelés]])

## A változások dokumentálása

Az alapelv: **semmi ne vesszen el, és mindig kiderüljön, mi, mikor és miért változott.**

| Mi történt | Hová írjuk | Hogyan |
|---|---|---|
| Eszedbe jutott valami | [[04 Ötletek]] | Új sor a táblázatban, állapot: 💭 – vagy sablon: `Sablonok/Ötlet` |
| Egy ötletet megvalósítunk | [[04 Ötletek]] + [[01 Specifikáció]] | Az ötlet állapota → ⚪ tervezett, melyik verzióban; a specifikációba új FR `🆕 v0.x.0` jelöléssel |
| Meglévő funkció módosul | [[01 Specifikáció]] | A követelmény mellett `🔄 v0.x.0`, és új sor a változástörténetben (mi + miért) |
| Funkció kikerül vagy elhalasztjuk | [[01 Specifikáció]] + [[04 Ötletek]] | Áthúzás és `❌ v0.x.0`, illetve `⏸`; indok a változástörténetben; ötletként felírva |
| Választani kell több megoldás közül | `Döntések/ADR-xxx` | Sablon: `Sablonok/Döntés (ADR)`; a régi döntést nem töröljük, hanem „felülírva: ADR-yyy” jelölést kap |
| Visszajelzés kézi tesztből | [[05 Tesztelés#Tesztkörök]] | Táblázat: Nézet \| Észrevétel \| Megoldás; a változás a specbe és a CHANGELOG-ba is |
| Hiba | GitHub Issue (+ opcionálisan [[06 Hibák]]) | Sablon: *Bug report* |
| Kiadott verzió | [[CHANGELOG]] | Hozzáadva / Módosítva / Javítva / Eltávolítva |

Obsidian-link táblázatban: a `|` jelet `\|`-ként kell írni, különben szétesik a táblázat.

## Mi kerülhet a nyilvános repóba

A repó nyilvános, ezért csak **semleges, bárkire érvényes** tartalom kerül bele.

| Nem kerülhet fel | Hová kerül helyette |
|---|---|
| Nevek, elérhetőségek, saját eszközök adatai, helyi elérési utak | `docs/_privat/` (nem verziózott) |
| Valódi listák, `.cetli` fájlok, mentések | sehova a repóban (a `.gitignore` kizárja; tesztadat csak a `test/fixtures` mappában) |
| Aláíró kulcsok, jelszavak, tokenek | GitHub Secrets + KeePass; a kulcsfájl a `docs/_privat/signing/` mappában |

Commit előtt GitHub Desktopban mindig nézd át a *Changes* listát: ha olyan fájl szerepel benne, ami nem oda való, ne commitold.

## Közös munka ugyanabban a mappában

- Claude a munkáját **mindig commitolva** adja át a saját ágán; a *Push origin* / *Publish branch* a te feladatod.
- Amíg a CI fut, vagy amíg azt mondod, „várj”, Claude nem nyúl a mappához.
- Ágat váltani csak akkor érdemes, ha a GitHub Desktop *Changes* listája **üres**. Ha a Desktop felajánlja, hogy „vigye magával” a változásokat (*Bring my changes*), válaszd inkább a **Leave my changes on …** lehetőséget, vagy szólj.
- Ütközésnél ne oldd fel kézzel – a változások visszanyerhetők, szólj.
