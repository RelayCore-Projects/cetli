---
tipus: specifikacio
dokumentum_verzio: 0.3.0
statusz: fejlesztés
frissitve: 2026-10-16
---

# Cetli – Specifikáció

## Változástörténet

| Verzió | Dátum | Változás | Indok / forrás |
|---|---|---|---|
| 0.1.0 | 2026-10-15 | Első változat (koncepció); a K-01…K-07 kérdések lezárva | Kiinduló igények, lásd [[#1. Cél]] és [[#9. Nyitott kérdések]] |
| 0.2.0 | 2026-10-16 | FR-05: a duplikátum üzenete a beviteli mező alatt jelenik meg | A 0.2.0 első CI-köre: a felugró üzenet eltakarta a beviteli mezőt |
| 0.2.0 | 2026-10-16 | **Új: FR-20** – listák kijelölése hosszú nyomással, több lista törlése egyszerre, átnevezés a kijelölésből | Igény a 0.2.0 Preview kipróbálása után: több lista egyszerre törölhető legyen |
| 0.3.0 | 2026-10-16 | FR-10: a **beépített tételek csak olvashatók**, csak a saját tételek szerkeszthetők és törölhetők; FR-17 és az adatmodell ehhez igazítva; a beépített lista átnézve (163 tétel, [[Katalógus – beépített tételek]]) | Igény a katalógus átnézésekor; [[ADR-007 Beépített katalógus az app részeként]] |

> [!info] Hogyan jelöljük a változásokat ebben a dokumentumban
> - Minden módosítás új sort kap a fenti táblázatban (verzió, dátum, mi, miért).
> - A módosított követelmény mellé kerül egy jelölés: `🔄 v0.x.0`, az újak mellé `🆕 v0.x.0`, az elhalasztottak mellé `⏸`.
> - A törölt követelményt nem töröljük, hanem áthúzzuk: ~~FR-xx …~~ `❌ v0.x.0`, és a változástörténetben megírjuk, miért.
> - A pontos szöveges különbséget a git őrzi (GitHub → a fájl *History* nézete).

---

## 1. Cél

Egy háztartás két tagja – mindkettő Android-telefonnal – **egymástól függetlenül** írhat bevásárlólistát, és a listákat
- **gyorsan** összeállítja: begépelve, automatikus kiegészítéssel vagy egy előre feltöltött, bővíthető termékkatalógusból válogatva,
- a boltban **vásárló módban** használja: a kosárba tett termékre koppint, az halványabb lesz és áthúzódik, de olvasható marad,
- **appon kívül megosztja** (például Messengeren küldött fájllal), a fogadó pedig a saját listájával **összefésüli, duplikátumok nélkül**.

Az app **offline** működik: nincs fiók, szerver és internet-engedély.

## 2. Hatókör

### Benne van (v1.0)
- Több lista; létrehozás, átnevezés, törlés
- Két mód: **szerkesztő** (gyors bevitel) és **vásárló** (kipipálás)
- Rendezés listánként: beírás sorrendje, név A–Z, név Z–A
- Opcionális megjegyzés tételenként (mennyiség, típus, márka)
- Termékkatalógus kb. 150 beépített angol tétellel, saját tételekkel, automatikus kiegészítéssel és többes kijelöléssel
- Lista megosztása és fogadása `.cetli` fájlként, összefésüléssel
- Teljes mentés és visszatöltés (minden lista + saját katalógus)
- Beállítások: a kipipált tételek helye, mentés, névjegy

### Nincs benne (v1.0) – lehetséges későbbi bővítések: [[04 Ötletek]]
- Élő, automatikus szinkron a két telefon között (szerverrel)
- Szöveges megosztás és beillesztés
- Kategóriák, bolti sorrend, kézi átrendezés
- Archiválás, kezdőképernyő-widget, téma választás, más nyelvű felület

## 3. Fogalmak

| Fogalom | Jelentés |
|---|---|
| **Lista** | Egy bevásárlólista névvel és tételekkel |
| **Tétel** | A lista egy sora: név, opcionális megjegyzés, kipipálva / nincs kipipálva |
| **Szerkesztő mód** | A lista írása: tétel felvétele, módosítása, törlése |
| **Vásárló mód** | A boltban: a tételek koppintással kipipálhatók, más nem változtatható |
| **Katalógus** | Az eszközön tárolt terméknevek gyűjteménye (beépített + saját); a bevitelt gyorsítja |
| **Névkulcs** | A név összehasonlításra normalizált alakja: a szélein levágott szóközök, a belső szóközök egyre vonva, kisbetűsítve. Ugyanaz a névkulcs = ugyanaz a tétel (`Bread` = `bread` = ` bread `). Az ékezet számít (`kenyér` ≠ `kenyer`) |
| **Összefésülés** | Egy fogadott lista tételeinek egyesítése egy meglévő listával, duplikátumok nélkül ([[#FR-16 Összefésülés szabályai]]) |
| **`.cetli` fájl** | Az app saját, verziózott JSON-fájlja egy listához vagy a teljes mentéshez |
| **Logikai törlés** | A törölt elem az adatbázisban törlésjelet kap, nem tűnik el; így az összefésülés nem hozza vissza |

## 4. Funkcionális követelmények

### 4.1 Listák

#### FR-01 Listák áttekintése (főképernyő)
- A főképernyő a listák felsorolása, a legutóbb módosított van felül.
- Soronként: a lista neve és az állapota, például `5 / 12` (kipipálva / összes).
- Koppintás: a lista megnyílik **vásárló módban** (FR-04). Hosszú nyomás: kijelölés (FR-20) `🆕 v0.2.0`
- `+` gomb: új lista (FR-02).
- Menü: *Catalog* (FR-10), *Import* (FR-15), *Settings* (FR-18).
- Üres állapot: rövid útmutatás („No lists yet. Tap + to create one.”).

#### FR-02 Lista létrehozása, átnevezése, törlése
- Új lista: névmegadó ablak, előtöltve a mai dátummal (pl. `List 15/10/2026`), átírható; a név kötelező, legfeljebb 40 karakter. Mentés után a lista **szerkesztő módban** nyílik meg.
- Átnevezés: a lista menüjéből.
- Törlés: a lista menüjéből, megerősítéssel; logikai törlés.

#### FR-03 Szerkesztő mód
- A képernyő alján beviteli mező (*Add item*). **Enter** vagy a hozzáadás gomb után a tétel bekerül, a mező kiürül, és **a billentyűzet nyitva marad** – a következő tétel azonnal írható.
- Gépelés közben automatikus kiegészítés (FR-11); a mező mellett *From catalog* gomb (FR-12).
- Tételre koppintva szerkeszthető a név és a megjegyzés; törlés ikonnal, *Undo* lehetőséggel.
- A tétel neve legfeljebb 60, a megjegyzés legfeljebb 100 karakter; üres név nem menthető.
- Kilépés: *Done* → vásárló mód.

#### FR-04 Vásárló mód
- Koppintás egy tételre: **kipipálva** – a sor halványabb, a név **áthúzott**, de olvasható marad. Újabb koppintás visszavonja.
- A fejlécben az állapot: `5 / 12`.
- Ebben a módban a tételek nem szerkeszthetők és nem törölhetők; a szerkesztő mód a fejléc ceruza ikonjával érhető el.
- A kipipált tételek helye a beállítás szerint (FR-08).

#### FR-05 Duplikátum kézi bevitelnél
- Ha a beírt név névkulcsa már szerepel a listán, **nem jön létre új tétel**:
  - ha a meglévő nincs kipipálva: rövid üzenet („Already on the list”) a beviteli mező alatt `🔄 v0.2.0`, és a tétel kiemelődik;
  - ha a meglévő ki van pipálva: a pipa lekerül róla (újra kell venni).
- A törölt tétel nem számít duplikátumnak.

#### FR-06 Megjegyzés
- Tételenként egy opcionális, szabad szöveges mező, például `2 l`, `x3`, `whole grain`, `Happy Day`.
- A név alatt kisebb, szürke betűvel jelenik meg; a duplikátumvizsgálat és a rendezés csak a nevet nézi.

#### FR-07 Rendezés
- Listánként választható: **Added order** (alapértelmezett) · **Name A–Z** · **Name Z–A**. Az app listánként megjegyzi (K-03).
- A név szerinti rendezés kis- és nagybetűtől független.
- Ha a kipipált tételek alulra kerülnek (FR-08), a rendezés a két csoporton belül érvényes.

#### FR-08 A kipipált tételek helye
- Általános beállítás: **Move to bottom** (alapértelmezett) vagy **Keep in place**.

#### FR-09 Vásárlás utáni műveletek
- A lista menüjében (K-04):
  - *Uncheck all* – minden pipa lekerül (a lista újra használható),
  - *Remove checked items* – a kipipált tételek törlése, megerősítéssel,
  - *Delete list* (FR-02).
- Automatikusan semmi nem történik.

### 4.2 Katalógus

#### FR-10 Katalógus kezelése
- Külön menüpont (*Catalog*). Kb. **150 beépített angol** tétel (pl. Bread, Milk, Sour cream, Banana) és a **saját** tételek.
- Ábécérendben, keresőmezővel (K-07).
- ~~Saját tétel felvétele, bármely tétel átnevezése és törlése. A beépített tétel törlése elrejti; frissítéskor sem jön vissza.~~ `❌ v0.3.0`
- Saját tétel felvétele, átnevezése és törlése (visszavonással); *My items* szűrő. **A beépített tételek nem szerkeszthetők és nem törölhetők.** `🔄 v0.3.0`
- A katalógusban a névkulcs egyedi.

#### FR-11 Automatikus kiegészítés
- Szerkesztő módban, az első beírt karaktertől legfeljebb 5 javaslat a katalógusból: előbb a névkulcs **elejére** illeszkedők, utána a **bárhol** illeszkedők, ábécérendben.
- A listán már szereplő (nem törölt) tételek nem jelennek meg javaslatként.
- Javaslatra koppintva a tétel bekerül, a mező kiürül, a billentyűzet nyitva marad.

#### FR-12 Választás a katalógusból
- *From catalog*: a katalógus ábécérendben, keresővel, **több tétel kijelölhető**. A listán már szereplők jelölten, nem választhatóan jelennek meg.
- *Add (n)*: a kijelöltek bekerülnek a listára.

#### FR-13 A katalógus bővülése
- Ha a listára olyan tétel kerül (kézzel vagy fogadott listából), amelynek névkulcsa nincs a katalógusban, **automatikusan saját tételként bekerül** (K-06).
- Az elírások is bekerülnek; a katalógusban javíthatók vagy törölhetők (FR-10).
- Ha a katalógusban egy tételt töröltek, a listára ugyanilyen néven újra felvett tétel ismét bekerül.

### 4.3 Megosztás és mentés

#### FR-14 Lista megosztása
- A lista menüjében *Share*: a lista `.cetli` fájlként (FR-17 formátum) az Android megosztás menüjébe kerül (pl. Messenger, e-mail, Drive).
- A fájl neve a lista neve, pl. `Weekly shop.cetli`.
- A fájl a törölt tételek törlésjelét is tartalmazza (FR-16).

#### FR-15 Lista fogadása
- Két út:
  1. a fájlt egy másik appból (pl. Messenger) **a Cetlivel megnyitva**, ha az Android és a küldő app ezt lehetővé teszi – valódi telefonon kell igazolni ([[ADR-004 Megosztás fájllal, szerver nélkül]]),
  2. **mindig működik**: főképernyő → *Import* → az Android fájlválasztója (pl. *Letöltések*).
- **Előnézet** összefésülés előtt: a fogadott lista neve, tételszáma, hány új, hány egyező, hány ütköző megjegyzés.
- **Cél kiválasztása:**
  - ha a lista már ismert (ugyanaz az azonosító, vagy korábban már ebbe a listába fésültük), alapértelmezetten abba,
  - különben választható: *Merge into…* (meglévő lista kiválasztása) vagy *Add as new list*.
- Az összefésülés után az app megjegyzi a kapcsolatot, így a következő fogadásnál nem kell újra választani.
- Hibás vagy újabb formátumverziójú fájlnál érthető hibaüzenet, adatváltozás nélkül.

#### FR-16 Összefésülés szabályai
- A tétel azonossága a listán belül a **névkulcs**. Az eredmény a két lista **uniója**.
- Csak az egyik oldalon szereplő tétel bekerül; mindkét oldalon szereplő tétel egyszer szerepel.
- Mindkét oldalon szereplő tételnél a **később módosított** állapot nyer (kipipálás, név írásmódja, törlés).
- **Megjegyzés:** ha a két oldalon eltér, és mindkettő nem üres, a kettő összefűzve megmarad (`whole grain; sliced`) – nem vész el adat.
- **Törlés:** a törlésjel is időbélyeget hordoz; ha a törlés későbbi, mint a másik oldal utolsó módosítása, a tétel törölve marad, különben visszakerül.
- A cél lista neve és rendezése nem változik.
- Az összefésülés **ismételhető**: ugyanannak a fájlnak az újbóli fogadása nem változtat semmit.

#### FR-17 Fájlformátum
- JSON, kiterjesztés `.cetli`, UTF-8.
- Fejléc: `format: "cetli"`, `format_version` (egész, 1-gyel indul), `kind` (`list` vagy `backup`), `exported_at` (UTC), `app_version`.
- Tartalom: listák (azonosító, név, időbélyegek) a tételeikkel (azonosító, név, megjegyzés, kipipálva, időbélyegek, törlésjel); mentésnél a ~~saját és a módosított / elrejtett beépített~~ **saját** katalógustételek is `🔄 v0.3.0`.
- Újabb **fő** formátumverziót a régi app nem tölt be, hanem frissítést kér ([[03 Fejlesztési folyamat#Verziószámozás]]).

#### FR-18 Teljes mentés és visszatöltés
- *Settings → Backup and restore*: *Save backup…* – minden lista és a katalógus egy `.cetli` fájlba (`kind: backup`), az Android fájlválasztójával kiválasztott helyre (pl. Google Drive).
- *Restore…*: előnézet, majd összefésülés listánként azonosító szerint (FR-16); a katalógus is összefésül. Semmi nem törlődik, ami nincs a mentésben.

### 4.4 Egyéb

#### FR-19 Beállítások és névjegy
- *Settings*: a kipipált tételek helye (FR-08), mentés és visszatöltés (FR-18), *About*.
- *About*: verziószám, licenc (MIT), a repó címe, „Your data stays on this device”.

#### FR-20 Listák kijelölése `🆕 v0.2.0`
- A főképernyőn egy listát **hosszan megnyomva** kijelölő mód indul; ebben a módban koppintásra további listák jelölhetők ki vagy vehetők ki.
- A felső sáv: ✕ (kilépés), „n selected”, *Select all*, *Rename* (csak pontosan egy kijelölt listánál), *Delete*.
- Törlés megerősítéssel (pl. „Delete 2 lists?”); logikai törlés.
- A vissza gomb előbb a kijelölést szünteti meg.
- A lista saját menüjében az átnevezés és a törlés továbbra is megvan (FR-02).

## 5. Nem funkcionális követelmények

| ID | Követelmény |
|---|---|
| NFR-01 | Android 8.0 (API 26) vagy újabb, 64 bites (arm64) telefon |
| NFR-02 | **Offline:** nincs INTERNET engedély, fiók, reklám vagy analitika; adat csak megosztással vagy mentéssel hagyja el a telefont |
| NFR-03 | A felület **angol** (`en_GB`: NN/HH/ÉÉÉÉ, 24 órás idő); minden felületi szöveg egy helyen van, hogy később fordítható legyen |
| NFR-04 | **Gyors bevitel:** egy tétel felvétele = gépelés + Enter (vagy egy koppintás a javaslatra); a billentyűzet nem csukódik be tételenként |
| NFR-05 | **Adatbiztonság:** logikai törlés; az adatbázisséma verziózott, minden migrációhoz automatikus teszt; frissítés adatvesztés nélkül települ |
| NFR-06 | **Olvashatóság:** a kipipált tétel halványítva is olvasható marad; az érinthető elemek legalább 48 dp-sek |
| NFR-07 | A téma (világos / sötét) a telefon beállítását követi |
| NFR-08 | **Minőség:** a CI minden pushnál statikus elemzést és automatikus teszteket futtat; a névkulcsra, az összefésülésre és a fájlformátumra egységtesztek; telefonméretű (432×960) widgettesztek |
| NFR-09 | **Professzionális repó:** angol nyelvű kód, commitok (Conventional Commits), issue-k, PR-ek és README; védett `main` ág; kiadás CHANGELOG-gal ([[ADR-002 Nyilvános repó, licenc és nyelvek]]) |

## 6. Adatmodell

Minden azonosító UUID, minden időbélyeg UTC.

**ShoppingList**

| Mező | Típus | Megjegyzés |
|---|---|---|
| `id` | UUID | |
| `name` | szöveg | 1–40 karakter |
| `sort_mode` | `added` \| `name_asc` \| `name_desc` | listánként (FR-07) |
| `created_at`, `updated_at` | időbélyeg | |
| `deleted_at` | időbélyeg, opcionális | logikai törlés |

**ListItem**

| Mező | Típus | Megjegyzés |
|---|---|---|
| `id` | UUID | |
| `list_id` | UUID | |
| `name` | szöveg | 1–60 karakter |
| `name_key` | szöveg | névkulcs; listán belül egyedi a nem törölt tételek között |
| `note` | szöveg, opcionális | legfeljebb 100 karakter |
| `checked` | logikai | |
| `created_at`, `updated_at` | időbélyeg | a `created_at` adja a beírás sorrendjét |
| `deleted_at` | időbélyeg, opcionális | törlésjel |

**ListLink** – a fogadott és a helyi lista kapcsolata (FR-15)

| Mező | Típus |
|---|---|
| `list_id` | UUID (helyi lista) |
| `foreign_id` | UUID (a fogadott lista azonosítója) |

**CatalogItem** – csak a saját tételek (`catalog_items`, séma v2) `🔄 v0.3.0`

| Mező | Típus | Megjegyzés |
|---|---|---|
| `id` | UUID | |
| `name`, `name_key` | szöveg | a `name_key` egyedi a nem törölt tételek között |
| ~~`builtin`~~ | ~~logikai~~ | ~~beépített tétel~~ – a beépített tételek nincsenek az adatbázisban |
| `created_at`, `updated_at` | időbélyeg | |
| `deleted_at` | időbélyeg, opcionális | törölt |

**Settings:** `checked_position` (`bottom` \| `in_place`).

~~A beépített katalógus az app része (asset). Első indításkor és frissítéskor a névkulcs szerint kerül az adatbázisba: új beépített tétel bekerül, az elrejtett nem jön vissza, a saját nem duplikálódik.~~ `❌ v0.3.0`
A beépített katalógus az app része (`assets/catalog/builtin_items.txt`), az adatbázisba nem kerül; az app a saját tételekkel a memóriában egyesíti ([[ADR-007 Beépített katalógus az app részeként]]). `🔄 v0.3.0`

## 7. Képernyők (vázlat)

```
Lists (főképernyő)          List – vásárló mód              List – szerkesztő mód
┌─────────────────────┐     ┌──────────────────────────┐    ┌──────────────────────────┐
│ Cetli            ⋮  │     │ ← Weekly shop  5/12  ✎ ⋮ │    │ ← Editing          Done  │
├─────────────────────┤     ├──────────────────────────┤    ├──────────────────────────┤
│ Weekly shop   5 / 12│     │ Bread                    │    │ Bread                  ✕ │
│ Party         0 / 8 │     │   whole grain            │    │   whole grain            │
│ DIY store     2 / 3 │     │ Milk                     │    │ Milk                   ✕ │
│                     │     │ ...                      │    │ ...                      │
│                     │     │ ~~Banana~~   (halvány)   │    ├──────────────────────────┤
│                 [+] │     │ ~~Sour cream~~           │    │ [Bread] [Breadcrumbs]    │
└─────────────────────┘     └──────────────────────────┘    │ br▌            [+] [≡]   │
 ⋮ Catalog · Import ·        ⋮ Sort · Share · Uncheck all ·  └──────────────────────────┘
   Settings                    Remove checked · Rename ·      [≡] From catalog
                               Delete list

Catalog / From catalog       Import – előnézet
┌──────────────────────┐     ┌───────────────────────────────┐
│ 🔍 Search            │     │ Weekly shop · 9 items         │
├──────────────────────┤     │ 4 new · 5 already on the list │
│ ☐ Apples             │     │ 1 note will be combined       │
│ ☑ Bananas            │     │                               │
│ ☐ Bread  (on list)   │     │ ◉ Merge into: Weekly shop ▾   │
│ ...                  │     │ ○ Add as new list             │
│            [Add (2)] │     │            [Cancel] [Merge]   │
└──────────────────────┘     └───────────────────────────────┘
```

## 8. Tervezett technológia

A részletek és az indoklás: [[ADR-001 Flutter és a technikai alapok]], [[ADR-004 Megosztás fájllal, szerver nélkül]].

| Terület | Megoldás |
|---|---|
| Keretrendszer | Flutter (a CI-ben rögzített verzió), Material 3 |
| Adat | SQLite (`sqflite`), repository minta, verziózott séma, migrációs tesztek |
| Fájlok | Megosztás: Android megosztás menü (`ACTION_SEND`, `FileProvider`); fogadás: *Open with* (`ACTION_VIEW`) és fájlválasztó (Storage Access Framework) – saját MethodChannelen, natív plugin nélkül |
| Fordítás, kiadás | GitHub Actions: elemzés, tesztek, aláírt APK, Preview és végleges Release |

## 9. Nyitott kérdések

| ID | Kérdés | Döntés | Dátum |
|---|---|---|---|
| K-01 | Hogyan kerül át a lista a másik telefonra? | **`.cetli` fájl** a megosztás menün át, pontos állapottal (időbélyeg, törlés, kipipálás). A szöveges megosztás ötlet maradt (Ö-002) → FR-14…17, [[ADR-004 Megosztás fájllal, szerver nélkül]] | 2026-10-15 |
| K-02 | Milyen nyelvű a repó? | **README angol, a `docs/` magyar**; a kód, a commitok, az issue-k és a PR-ek angolok → NFR-09, [[ADR-002 Nyilvános repó, licenc és nyelvek]] | 2026-10-15 |
| K-03 | Hol állítható a rendezés? | **Listánként**, az app megjegyzi → FR-07 | 2026-10-15 |
| K-04 | Mi legyen a listával vásárlás után? | **Kézi műveletek:** *Uncheck all*, *Remove checked items*, *Delete list*; az archiválás ötlet (Ö-011) → FR-09 | 2026-10-15 |
| K-05 | Legyen teljes mentés? | **Igen, a v1.0-ban** → FR-18 | 2026-10-15 |
| K-06 | A fogadott lista ismeretlen tételei bekerülnek a katalógusba? | **Igen, automatikusan** → FR-13 | 2026-10-15 |
| K-07 | Hogyan rendezett a katalógusválasztó? | **A–Z + keresés**; a kategóriák és a gyakoriság szerinti sorrend ötlet (Ö-003, Ö-004) → FR-10, FR-12 | 2026-10-15 |

## 10. Elfogadási feltételek (v1.0)

- Minden FR teljesül, nincs nyitott 🔴 vagy 🟠 hiba ([[06 Hibák]]).
- A kézi tesztlista ([[05 Tesztelés]]) két valódi telefonon lefutott.
- **Kétirányú forgatókönyv** sikeres: két telefonon egymástól függetlenül írt lista (közös, eltérő írásmódú és csak az egyik oldalon szereplő tételekkel) → küldés Messengeren → fogadás → összefésülés → visszaküldés → mindkét telefonon ugyanaz a lista, duplikátum nélkül.
- Mentés → az app törlése → újratelepítés → visszatöltés: minden lista és a saját katalógus megvan.
- A frissítés a korábbi verzióra adatvesztés nélkül települ.
