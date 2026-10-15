---
tipus: adr
azonosito: ADR-004
statusz: elfogadva
datum: 2026-10-15
felulirja:
felulirva_altala:
---

# ADR-004 – Megosztás fájllal, szerver nélkül

## Kontextus
Két ember két telefonon, egymástól függetlenül ír listát, és ezeket appon kívül (jellemzően Messengeren) küldi át egymásnak. A fogadó a saját listájával fésüli össze, duplikátumok nélkül. A két külön írt listának nincs közös azonosítója, és ugyanazt a terméket eltérően írhatják (`Bread` / `bread`). Az app offline (NFR-02).

## Lehetőségek
| | Előny | Hátrány |
|---|---|---|
| A – `.cetli` fájl (JSON) a megosztás menün át | Pontos állapot (időbélyeg, kipipálás, törlés); többkörös oda-vissza küldésre is helyes; offline | Messengerből a megnyitás telefonfüggő, ezért kell fájlválasztós tartalék |
| B – Szöveg a vágólapon át | Messengeren a legbiztosabb, app nélkül is olvasható | Kipipálás és törlés nem utazik át; csak unió |
| C – Élő szinkron szerverrel | Automatikus, mindig friss | INTERNET engedély, fiók, backend, üzemeltetés, adatvédelem – más projektméret |

## Döntés
**A** (K-01). A B és a C ötlet (Ö-002, Ö-001).

**Azonosítás és összefésülés** (FR-16):
- A tétel azonossága a listán belül a **névkulcs** (levágott és összevont szóközök, kisbetű) – így a függetlenül írt `Bread` és `bread` egy tétel.
- Unió; azonos tételnél a később módosított állapot nyer; eltérő, nem üres megjegyzések összefűzve megmaradnak.
- A törlés időbélyeges törlésjel, hogy egy későbbi összefésülés ne hozza vissza a törölt tételt.
- A fogadott listát az első alkalommal a felhasználó rendeli egy helyi listához (vagy újként veszi fel); az app ezt megjegyzi (`ListLink`).
- Az összefésülés idempotens: ugyanaz a fájl kétszer fogadva nem változtat.

**Fájlkezelés:** küldés `ACTION_SEND`-del és `FileProvider`-rel; fogadás *Open with*-szel (`ACTION_VIEW`), tartalékként az Android fájlválasztójával. Saját MethodChannelen, plugin nélkül ([[ADR-001 Flutter és a technikai alapok]]).

## Következmények
- Nincs internet-engedély, a két telefon adatai csak a felhasználók döntésével utaznak.
- A lista nem frissül magától: a változást újra el kell küldeni. Két felhasználónál ez elfogadható („indulok a boltba, küldd át”).
- A `.cetli` formátum verziózott (`format_version`); nem kompatibilis változás fő verzióváltást jelent.
- Hogy a Messenger által kapott fájl közvetlenül a Cetlivel nyitható-e, a 0.4.0 Preview-ján, két valódi telefonon derül ki; a fájlválasztós import mindenképp működik.
