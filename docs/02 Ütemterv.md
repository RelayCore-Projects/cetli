---
tipus: utemterv
frissitve: 2026-10-16
---

# Ütemterv

Minden verzió egy lezárt, kipróbálható lépés. A verziószámozás szabályai: [[03 Fejlesztési folyamat#Verziószámozás]].

**Kevés, nagyobb verzió:** egy CI-kör (elemzés, tesztek, aláírt APK) 8–10 perc, ezért egy verzió egy teljes, használható funkciócsoportot tartalmaz. Egy verzión belül a Preview-k (`x.y.z-dev.N`) adják a köztes kipróbálható állapotot.

| Verzió | Tartalom | Fázis | Állapot |
|---|---|---|---|
| **0.1.0** | Koncepció: specifikáció, döntések (ADR-001…004), projektdokumentáció, README, GitHub-sablonok | Koncepció | 🟢 kész |
| 0.2.0 | Flutter projektváz, CI, aláírt APK · adatbázis · **listák** (FR-01, 02), **szerkesztő és vásárló mód** (FR-03, 04), duplikátum (FR-05), megjegyzés (FR-06), rendezés (FR-07), a kipipáltak helye és a beállítások váza (FR-08, 19), vásárlás utáni műveletek (FR-09), listák kijelölése `🆕` (FR-20) · saját ikon `🔄` ([[ADR-006 Alkalmazásikon\|ADR-006]]) · CI és aláírás: [[ADR-005 Fordítás, aláírás és kiadás a GitHub Actionsben\|ADR-005]] | Fejlesztés | 🟢 kész |
| 0.3.0 | **Katalógus** a beépített tételekkel (FR-10), automatikus kiegészítés (FR-11), választás a katalógusból (FR-12), automatikus bővülés (FR-13) · ~~saját ikon~~ → 0.2.0 · a beépített tételek csak olvashatók `🔄` ([[ADR-007 Beépített katalógus az app részeként\|ADR-007]]) | Fejlesztés | 🟡 folyamatban |
| 0.4.0 | **Megosztás és fogadás** `.cetli` fájllal, összefésülés (FR-14…17), **teljes mentés** (FR-18) | Fejlesztés | ⚪ tervezett |
| **1.0.0** | Első stabil kiadás: teljes kézi tesztkör két telefonon, az elfogadási feltételek ([[01 Specifikáció#10. Elfogadási feltételek (v1.0)]]) | Kiadás | ⚪ tervezett |

**Jelmagyarázat:** 💭 ötlet · ⚪ tervezett · 🟡 folyamatban · 🟢 kész · 🔴 elakadt · ⛔ elvetve / beolvasztva

Hibajavításhoz külön patch-verzió (`0.x.1`) készül, így az 1.0.0 pontosan a tesztelt kód.

## Mérföldkő-napló

Ide kerül, mikor zárult le egy verzió (dátum + rövid megjegyzés). A részletes tartalom a [[CHANGELOG]]-ban.

- 2026-10-15 – Projekt indítása: név (Cetli), repó és vault létrehozva
- 2026-10-15 – 0.1.0: koncepció, K-01…K-07 lezárva
- 2026-10-16 – Aláírókulcs és GitHub-secretek elkészültek; a 0.2.0 fejlesztése elindult (`feature/lists`). A saját ikon előrekerült a 0.2.0-ba, mert az első APK-hoz úgyis kell ikon
- 2026-10-16 – **0.2.0:** listák, szerkesztő és vásárló mód, rendezés, beállítások, listák kijelölése (FR-20, a Preview kipróbálása után), saját ikon; két CI-kör, a Preview kézi tesztje rendben
- 2026-10-16 – 0.3.0 fejlesztése elindult (`feature/catalog`): a beépített lista átnézve (163 tétel), a beépített tételek csak olvashatók
