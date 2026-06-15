# realrpg_detector – több zónás detektorozás

SeeRPG-hangulatú detektorozás rendszer FiveM **ESX Legacy + ox_inventory** szerverhez.

Ez a verzió már nem csak egy területen működik, hanem több külön detektorozható zónát kezel. Minden zónának saját keresési pontjai és saját jutalom táblája van, így mást és más értékű dolgot lehet találni területenként.

## Fő funkciók

- Fémkereső itemmel ki-be kapcsolható detektor: `femkereso`.
- A detektor objektum megjelenik a karakter jobb kezében.
- Ásó item: `aso`.
- Az ásó külön is elővehető, ásáskor pedig automatikusan a karakter kezébe kerül.
- Jobb oldali zöld radar panel, koordinátákkal és aktuális területnévvel.
- Közeledésnél gyorsuló csipogás.
- Több kereshető zóna, külön jutalmakkal:
  - Cayo Perico – drog alapanyag ládák, nagyobb értékek.
  - Grand Senora Desert – olcsóbb fémdarabok, régi érme, alkatrész.
  - Paleto Forest – elrejtett csomagok, okmány táska, ékszeres ládika.
  - Mount Chiliad – aranyrög, gyémánt, antik tárgyak, kincsesláda.
  - Los Santos Docks – csempész csomagok, elektronikai ládák, adattárolók.
- A talált ládán megjelenik:
  - név,
  - súly,
  - terület,
  - becsült érték.
- ox_inventory metadata-ba is bekerül:
  - `estimatedValue`,
  - `value`,
  - `tier`,
  - `zoneId`,
  - `zoneLabel`,
  - `areaName`,
  - `foundAt`.
- Szerveroldali védelem:
  - fémkereső item ellenőrzés,
  - ásó item ellenőrzés,
  - távolság check,
  - pont foglaltság,
  - láda tulajdonos check,
  - inventory full check,
  - pont respawn.

## Telepítés

1. Másold a `realrpg_detector` mappát a `resources` mappádba.
2. `server.cfg`:

```cfg
ensure realrpg_detector
```

3. Ha ox_inventory-t használsz, másold be az `install/ox_inventory_items.lua` tartalmát az `ox_inventory/data/items.lua` fájlba.
4. Az ikonokat másold ide:

```txt
install/web_images/femkereso.png -> ox_inventory/web/images/femkereso.png
install/web_images/aso.png       -> ox_inventory/web/images/aso.png
```

5. Restart:

```cfg
restart ox_inventory
restart realrpg_detector
```

6. Teszt itemek:

```txt
femkereso
aso
```

## Új zónák szerkesztése

A teljes több helyszínes logika a `config.lua` fájlban van itt:

```lua
Config.DetectorZones = {
    {
        id = 'cayo_drog',
        label = 'Cayo Perico - illegális alapanyag lelőhely',
        areaName = 'Cayo Perico',
        respawnMinutes = 35,
        rewards = {
            { name = 'drog_alapanyag_lada', label = 'Drog alapanyag láda', chance = 55, value = 45000 },
            { name = 'ritka_drog_alapanyag_lada', label = 'Ritka drog alapanyag láda', chance = 6, value = 220000 }
        },
        points = {
            vector3(4506.21, -4521.83, 4.18)
        }
    }
}
```

### Fontos mezők

- `id` – egyedi zóna azonosító.
- `label` – admin / metadata név.
- `areaName` – ez jelenik meg a radar panelen.
- `respawnMinutes` – ezen a zónán belül hány perc után jöjjön vissza egy kiásott pont.
- `rewards` – csak ezen a zónán található itemek.
- `points` – koordináták, ahol detektorozni lehet.
- `chance` – esély súly. Nem kell összesen 100-nak lennie.
- `value` – becsült érték. Ez nem automatikus pénz, hanem metadata és láda felirat. Eladáshoz a saját sell scriptedben használd.
- `crateStyle` – láda vizuális kiemelés: `white`, `green`, `blue`, `rare`, `gold`.

## Admin reset

```txt
/detektorreset
```

ACE jogosultság:

```cfg
add_ace group.admin realrpg.detector.admin allow
```

## Megjegyzés az értékekhez

A script alapból itemet ad, nem pénzt. A `value` csak becsült érték és metadata. Ez azért jobb, mert így később tudsz külön illegális felvásárlót / NPC eladót csinálni, aki zónánként vagy itemenként más áron veszi át a leleteket.

Példa metadata ox_inventory itemen:

```lua
metadata = {
    estimatedValue = 75000,
    tier = 'értékes',
    areaName = 'Cayo Perico',
    foundAt = '2026-06-15 20:00:00'
}
```

## Teszt parancs

Alapból ki van kapcsolva, mert itemes használatra készült. Fejlesztéshez visszakapcsolható:

```lua
Config.Commands.testToggle = true
```

Utána:

```txt
/detektor
```
