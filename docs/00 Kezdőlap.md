---
tipus: kezdolap
projekt: Cetli
aktualis_verzio: 0.2.0 (fejlesztés alatt)
fazis: Fejlesztés
frissitve: 2026-10-16
---

# Cetli – projekt kezdőlap

Egyszerű, offline bevásárlólista Androidra, fájlos megosztással és összefésüléssel. **RelayCore-Projects** · repó: [RelayCore-Projects/cetli](https://github.com/RelayCore-Projects/cetli)

## Hol tartunk

| | |
|---|---|
| Aktuális verzió | **0.1.0 – koncepció** · fejlesztés alatt: 0.2.0 |
| Fázis | Koncepció ✅ → *Fejlesztés* → Tesztelés → Hibajavítás → Kiadás |
| Következő lépés | **0.2.0** Preview kipróbálása telefonon: listák, szerkesztő és vásárló mód ([[02 Ütemterv]], [[05 Tesztelés]]) |

## Dokumentumok

1. [[01 Specifikáció]] – mit tud az app, képernyők, adatmodell, követelmények
2. [[02 Ütemterv]] – verziók és mérföldkövek
3. [[03 Fejlesztési folyamat]] – verziózás, ágak, commitok, kiadás, a változások dokumentálása
4. [[04 Ötletek]] – ide írd, ami eszedbe jut
5. [[05 Tesztelés]] – tesztstratégia és kézi tesztlista
6. [[06 Hibák]] – hogyan jelentsünk és kövessünk hibát
7. [[CHANGELOG]] – verziónként mi változott
8. **Döntésnapló** (miért döntöttünk így):
   - [[ADR-001 Flutter és a technikai alapok]]
   - [[ADR-002 Nyilvános repó, licenc és nyelvek]]
   - [[ADR-003 Repó- és vault-szerkezet]]
   - [[ADR-004 Megosztás fájllal, szerver nélkül]]
   - [[ADR-005 Fordítás, aláírás és kiadás a GitHub Actionsben]]

## Privát jegyzetek

A `_privat` mappa csak ezen a gépen létezik, **nem kerül fel a GitHubra**. Ide kerül minden személyes adat és az aláírókulcs. Szabályok: [[03 Fejlesztési folyamat#Mi kerülhet a nyilvános repóba]].

## Sablonok

A `Sablonok` mappában: új ötlet, új döntés (ADR), hibajegyzet.
Beszúrás: parancspaletta (`Ctrl+P`) → *Templates: Insert template*.

## Szabály röviden

> Minden változás nyomot hagy: **ötlet** → [[04 Ötletek]], **döntés** → új ADR, **követelmény-módosítás** → [[01 Specifikáció]] változástörténete, **kiadott változás** → [[CHANGELOG]].
> Részletek: [[03 Fejlesztési folyamat#A változások dokumentálása]].
