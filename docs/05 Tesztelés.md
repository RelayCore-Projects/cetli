---
tipus: teszteles
frissitve: 2026-10-16
---

# Tesztelés

## Tesztszintek

| Szint | Mit ellenőriz | Ki / mikor |
|---|---|---|
| **Egységteszt** (unit) | Névkulcs, duplikátum, rendezés, összefésülés, fájlformátum, adatbázis-migrációk | Automatikusan, minden pushnál (GitHub Actions) |
| **Widget-teszt** | Egy-egy képernyő viselkedése telefonméretben (432×960), pl. a billentyűzet nyitva marad, áthúzás | Automatikusan |
| **Kézi elfogadási teszt** | A lenti tesztlista valódi Android-telefonon (a megosztásnál kettőn) | Minden Preview-nál a változott részre, kiadás előtt a teljes listára |

Ha egy automatikus teszt elbukik, a GitHubon piros ❌ jelenik meg, és nem adunk ki verziót.

## Telepítés a telefonra

1. Telefonon nyisd meg: **github.com/RelayCore-Projects/cetli/releases**
   - **Preview** – a legutóbbi fejlesztői fordítás
   - **Cetli x.y.z** – végleges kiadások
2. Az *Assets* alatt koppints a `cetli-….apk` fájlra → letöltés
3. Nyisd meg a letöltött fájlt → első alkalommal az Android engedélyt kér a böngészőnek az „ismeretlen alkalmazások telepítéséhez” → engedélyezd → *Telepítés*
4. Frissítésnél ugyanígy: az új APK a régire települ, az adatok megmaradnak
5. A telepített verziót a *Settings → About* mutatja

> Ha a Google Play Protect figyelmeztet („ismeretlen fejlesztő”), az azért van, mert az app nem a Play Áruházból jön: *További részletek → Telepítés mindenképp*.

## Kézi tesztlista

| ID | Lépések | Elvárt eredmény | FR |
|---|---|---|---|
| T-01 | Első indítás | Üres főképernyő útmutatással | FR-01 |
| T-02 | `+` → név elfogadása | A lista dátumos névvel létrejön, szerkesztő módban nyílik | FR-02 |
| T-03 | Szerkesztő módban 5 tétel gépelése, mindegyik után Enter | Mind bekerül, a billentyűzet végig nyitva marad | FR-03, NFR-04 |
| T-04 | `bread` beírása, amikor `Bread` már a listán van | Nincs új tétel, „Already on the list” | FR-05 |
| T-05 | Kipipált `Milk` mellett `milk` beírása | A `Milk` pipája lekerül, nincs új tétel; az üzenet a beviteli mező alatt jelenik meg, nem takarja el | FR-05 |
| T-06 | Tételre koppintás szerkesztő módban → megjegyzés: `whole grain` | A név alatt szürkén megjelenik | FR-06 |
| T-07 | Tétel törlése → *Undo* | A tétel visszakerül | FR-03 |
| T-08 | *Done* → vásárló mód, koppintás egy tételre | Halványabb, áthúzott, olvasható; az állapot nő; újabb koppintás visszavonja | FR-04 |
| T-09 | Vásárló módban hosszú nyomás / húzás egy tételen | Nem szerkeszthető, nem törölhető | FR-04 |
| T-10 | Beállítás: *Move to bottom*, majd *Keep in place* | A kipipáltak alulra kerülnek, illetve a helyükön maradnak | FR-08 |
| T-11 | Rendezés A–Z, Z–A, Added order; az app újraindítása | A sorrend helyes, listánként megmarad | FR-07 |
| T-12 | *Uncheck all*, *Remove checked items*, lista átnevezése és törlése | A művelet megtörténik, törlésnél megerősítést kér | FR-02, FR-09 |
| T-13 | Gépelés: `br` | Legfeljebb 5 javaslat, a `Bread` elöl; koppintásra bekerül | FR-11 |
| T-14 | *From catalog* → 3 tétel kijelölése → *Add (3)* | Mindhárom a listára kerül; a már ott lévők nem választhatók | FR-12 |
| T-15 | Új név beírása (pl. `Tesco Jaffa Cakes`) | Megjelenik a katalógusban saját tételként | FR-13 |
| T-16 | Katalógus: keresés, saját tétel felvétele, átnevezése, beépített tétel törlése | Működik; az elrejtett beépített tétel nem tér vissza újraindítás után | FR-10 |
| T-17 | *Share* → Messenger → a másik telefonon megnyitás a Cetlivel | Előnézet, majd összefésülés | FR-14, FR-15 |
| T-18 | Ha T-17 nem nyitja meg: Letöltések → *Import* | Ugyanaz az eredmény | FR-15 |
| T-19 | Két telefonon független lista (`Bread` / `bread`, közös és egyedi tételek, eltérő megjegyzés) → összefésülés mindkét irányban | Unió, duplikátum nélkül, a megjegyzések összefűzve; másodszori fogadás nem változtat semmit | FR-16 |
| T-20 | A-n tétel törlése → küldés B-nek → összefésülés | A tétel B-n is törlődik | FR-16 |
| T-21 | Fogadás után a fogadó katalógusa | A fogadott ismeretlen tételek benne vannak | FR-13 |
| T-22 | Hibás fájl importálása (pl. egy kép) | Érthető hibaüzenet, semmi nem változik | FR-15 |
| T-23 | *Save backup…* → app törlése → újratelepítés → *Restore…* | Minden lista és a saját katalógus visszajön | FR-18 |
| T-24 | Frissítés az előző kiadott verzióról | Az adatok megmaradnak | NFR-05 |
| T-25 | Sötét téma a telefonon | A felület sötét, a kipipált tételek is olvashatók | NFR-06, NFR-07 |
| T-26 | *About* | Verzió, licenc, repó címe | FR-19 |
| T-27 | Főképernyő: hosszú nyomás egy listán → koppintás egy másikon → *Delete* → megerősítés; egy kijelölt listánál *Rename*; vissza gomb kijelölés közben | Mindkét lista törlődik; az átnevezés működik; a vissza gomb csak a kijelölést szünteti meg | FR-20 |

## Tesztkörök

Verziónként: dátum, Preview / kiadás, eszközök, eredmény. Visszajelzésnél táblázat:

| Nézet | Észrevétel | Megoldás |
|---|---|---|

### v0.2.0 – Preview kézi tesztje (2026-10-16)

Saját telefonon: listák létrehozása, gyors bevitel, vásárló mód, rendezés, beállítások, új ikon – rendben.

| Nézet | Észrevétel | Megoldás |
|---|---|---|
| Főképernyő | Több listát is lehessen egyszerre törölni; hosszú nyomásra jöjjön szerkesztési lehetőség | Új FR-20: kijelölés hosszú nyomással, *Rename* (egy listánál), *Delete* (többnél is), *Select all* |

### v0.2.0 – első CI-kör (2026-10-16)

Elemzés és APK-fordítás hibátlan, 45 / 46 automatikus teszt sikeres.

| Nézet | Észrevétel | Megoldás |
|---|---|---|
| Szerkesztő mód | Duplikátumnál a felugró üzenet (SnackBar) eltakarta a beviteli mezőt és a + gombot; a widgetteszt ezt megfogta | Az üzenet a beviteli mező alá került, gépeléskor eltűnik |
| CI | A bukott widgetteszt oka nem látszott az annotációban | A `tool/ci_test_annotations.py` a kiírt kivételnaplót is csatolja |
| CI | Az `ubuntu-latest` október 19-től Ubuntu 26-ra vált – a rögzített NDK eltűnhet | A futtatókörnyezet rögzítve: `ubuntu-24.04` |
