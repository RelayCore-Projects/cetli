---
tipus: adr
azonosito: ADR-002
statusz: elfogadva
datum: 2026-10-15
felulirja:
felulirva_altala:
---

# ADR-002 – Nyilvános repó, licenc és nyelvek

## Kontextus
A repó nyilvános, és referenciaként is szolgál: aki megnyitja, egy rendezett, professzionálisan vezetett projektet lásson. Közben a tervezési dokumentációt a fejlesztő magyarul vezeti Obsidianban (K-02).

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| A – README angol, `docs/` magyar | Az első benyomás nemzetközileg olvasható; a tervezés a fejlesztő nyelvén megy | Két nyelv a repóban |
| B – Minden angol | Egységes, nemzetközi | A napi tervezési munka idegen nyelven |
| C – Minden magyar | Egyszerű | Nemzetközi olvasónak érthetetlen |

## Döntés
**A**, kiegészítve:
- Nyilvános repó a `RelayCore-Projects` szervezetben, **MIT licenc**, copyright: „RelayCore-Projects”; személynév nem kerül az appba és a dokumentációba
- **Angol:** README, forráskód és kódkommentek, commit-üzenetek ([Conventional Commits](https://www.conventionalcommits.org)), issue-k, PR-ek, kiadási jegyzetek fejléce, az app felülete
- **Magyar:** a `docs/` vault (specifikáció, döntések, ütemterv, tesztelés, CHANGELOG)
- Professzionális keretek: védett `main` ág (PR + zöld CI), issue- és PR-sablonok, CI-jelvény, Release-ek a CHANGELOG-ból

## Következmények
- A README jelzi, hogy a tervezési dokumentáció magyar.
- A GitHub Release szövege a magyar CHANGELOG-ból jön; ez a kiadási folyamatban külön döntés lehet (0.2.0).
