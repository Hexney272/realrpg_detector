Config = {}

-- ESX Legacy + ox_inventory kompatibilis alapbeállítások
Config.Framework = 'esx'
Config.Inventory = 'ox' -- 'ox' vagy 'esx'
Config.RegisterUsableDetector = true -- ESX usable item regisztráció
Config.Debug = false

Config.Items = {
    detector = 'femkereso',
    shovel = 'aso'
}

Config.Economy = {
    currency = '$',
    showEstimatedValueOnCrate = true,
    showZoneOnCrate = true
}

Config.ItemUse = {
    -- true = a /detektor vagy direkt kliens event is csak akkor kapcsol, ha a szerver lát nálad fémkereső itemet
    requireDetectorItemForToggle = true,

    -- true = az ásó item önmagában is elővehető/elrakható roleplay célra.
    -- Ásásnál ettől függetlenül automatikusan megjelenik a kézben.
    shovelCanBeEquipped = true,

    -- Detektor használat közben kapjon-e egy egyszerű tartó idle animot.
    -- Ha nálad rosszul néz ki, állítsd false-ra.
    playDetectorIdleAnim = false
}

Config.Detector = {
    -- A videóban jobb oldalon megjelenő radar-szerű panel viselkedése
    scanRange = 85.0,               -- ekkora távon belül kezd jelezni a detektor
    iconRenderDistance = 65.0,      -- világban látható kis szürke ikonok távolsága
    digDistance = 2.15,             -- ennyire kell közel állni az ásáshoz
    pickupDistance = 2.0,           -- láda felvételi táv
    digTimeMs = 6500,               -- ásás ideje
    respawnMinutes = 35,            -- mennyi idő után jelenjen meg újra ugyanaz a pont
    crateLifetimeMinutes = 8,       -- felfedett láda meddig maradjon felvehető
    beepEnabled = true,
    beepSlowMs = 1150,
    beepFastMs = 180,
    requireShovel = true,
    removeShovelChance = 0,         -- 0 = sosem törik el; pl. 8 = 8% eséllyel elveszi
    areaName = 'Ismeretlen terület' -- fallback, ha egy pontnál nincs megadva zóna
}

Config.Controls = {
    dig = 38,       -- E
    pickup = 38,    -- E
    cancel = 73,    -- X
    cursorKey = 'COMMA'  -- Vessző gomb (,) a kurzor be/ki kapcsoláshoz (ne ütközzön más scripttel)
}

Config.Commands = {
    -- Itemes használatnál alapból false. Fejlesztéshez visszakapcsolhatod.
    testToggle = false,
    testToggleName = 'detektor',
    adminReset = true,
    adminResetName = 'detektorreset',
    adminAce = 'realrpg.detector.admin'
}

Config.Models = {
    -- A script sorban megpróbálja betölteni ezeket. Az első működő modell kerül a kézbe.
    -- Ha valamelyik artifact/build alatt más néven van meg, itt könnyen állítható.
    detector = {
        'w_am_digiscanner',
        'ch_prop_ch_metal_detector_01a',
        'prop_detector_01'
    },
    detectorFallback = 'prop_tool_box_04',
    shovel = {
        'prop_tool_shovel',
        'prop_ld_shovel'
    },
    crate = 'prop_box_ammo03a'
}

Config.Attachments = {
    detector = {
        bone = 57005, -- jobb kéz
        x = 0.16,
        y = 0.03,
        z = -0.05,
        rx = -95.0,
        ry = 0.0,
        rz = 18.0
    },
    shovel = {
        bone = 57005, -- jobb kéz
        x = 0.12,
        y = -0.03,
        z = -0.04,
        rx = -100.0,
        ry = 10.0,
        rz = 15.0
    }
}

-- Több külön detektorozható terület.
-- Minden zóna saját pontlistát és saját jutalom táblát kap.
-- A chance értékek egymáshoz viszonyított súlyok, nem kell összesen 100-nak lenniük.
-- value = becsült érték, ami metadata-ba és láda feliratba kerül.
--
-- KÉTFÉLE PONT RENDSZER TÁMOGATOTT:
--   1) RÉGI: points = { vector3(...), ... }  — fix pontok
--   2) ÚJ (PolyZone): polygon + pointCount — véletlenszerű pontok generálása a területen belül
--      polygon = { vec2(x,y), ... }  — a terület határa (min. 3 pont, zárt poligon)
--      pointCount = 20               — hány pont generálódjon a területen belül
--      minZ / maxZ                   — magassági tartomány (Z koordináta)
--      minDistance = 15.0            — minimum távolság pontok között
--
-- Ha egy zónánál MINDKETTŐ meg van adva, a polygon elsőbbséget élvez.
-- A pontok MINDEN szerver újraindításkor (és /detektorreset-kor) újragenerálódnak!
Config.DetectorZones = {
    {
        id = 'cayo_drog',
        label = 'Cayo Perico - illegális alapanyag lelőhely',
        areaName = 'Cayo Perico',
        respawnMinutes = 35,
        -- PolyZone mód: pontok véletlenszerűen generálódnak ezen a területen
        polygon = {
            vector2(4480.0, -4550.0),
            vector2(4550.0, -4450.0),
            vector2(4750.0, -4450.0),
            vector2(4900.0, -4600.0),
            vector2(5300.0, -5120.0),
            vector2(5100.0, -5200.0),
            vector2(4600.0, -4700.0)
        },
        pointCount = 20,
        minZ = 2.0,
        maxZ = 25.0,
        minDistance = 25.0,
        rewards = {
            { name = 'drog_alapanyag_lada',       label = 'Drog alapanyag láda',       weight = 3000, chance = 55, min = 1, max = 1, value = 45000,  tier = 'közepes', crateStyle = 'white' },
            { name = 'drog_alapanyag_lada_zold',  label = 'Zöld drog alapanyag láda',  weight = 3000, chance = 25, min = 1, max = 1, value = 75000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'drog_alapanyag_lada_kek',   label = 'Kék drog alapanyag láda',   weight = 3000, chance = 14, min = 1, max = 1, value = 120000, tier = 'ritka', crateStyle = 'blue' },
            { name = 'ritka_drog_alapanyag_lada', label = 'Ritka drog alapanyag láda', weight = 3000, chance = 6,  min = 1, max = 1, value = 220000, tier = 'nagyon ritka', crateStyle = 'rare' }
        }
    },
    {
        id = 'grand_senora_low',
        label = 'Grand Senora - olcsó roncs lelőhely',
        areaName = 'Grand Senora Desert',
        respawnMinutes = 22,
        polygon = {
            vector2(1490.0, 3060.0),
            vector2(1550.0, 3050.0),
            vector2(2350.0, 3870.0),
            vector2(2280.0, 3930.0),
            vector2(1500.0, 3120.0)
        },
        pointCount = 16,
        minZ = 34.0,
        maxZ = 42.0,
        minDistance = 20.0,
        rewards = {
            { name = 'rozsdas_femdarab',     label = 'Rozsdás fémdarab',          weight = 800,  chance = 48, min = 1, max = 3, value = 2500,  tier = 'olcsó', crateStyle = 'white' },
            { name = 'regi_erme',            label = 'Régi érme',                 weight = 100,  chance = 30, min = 1, max = 2, value = 8500,  tier = 'olcsó', crateStyle = 'white' },
            { name = 'katonai_alkatresz',    label = 'Régi katonai alkatrész',    weight = 1200, chance = 17, min = 1, max = 1, value = 18000, tier = 'közepes', crateStyle = 'green' },
            { name = 'arany_karora',         label = 'Elásott arany karóra',      weight = 250,  chance = 5,  min = 1, max = 1, value = 42000, tier = 'ritka', crateStyle = 'rare' }
        }
    },
    {
        id = 'paleto_forest_mid',
        label = 'Paleto erdő - elrejtett csomagok',
        areaName = 'Paleto Forest',
        respawnMinutes = 30,
        polygon = {
            vector2(-490.0, 5350.0),
            vector2(-480.0, 5340.0),
            vector2(-1050.0, 5970.0),
            vector2(-1120.0, 6080.0),
            vector2(-1130.0, 6070.0),
            vector2(-540.0, 5420.0)
        },
        pointCount = 14,
        minZ = 3.0,
        maxZ = 75.0,
        minDistance = 30.0,
        rewards = {
            { name = 'elrejtett_keszpenz_csomag', label = 'Elrejtett készpénz csomag', weight = 600,  chance = 42, min = 1, max = 1, value = 28000, tier = 'közepes', crateStyle = 'white' },
            { name = 'hamis_okmany_taska',        label = 'Hamis okmány táska',        weight = 1200, chance = 30, min = 1, max = 1, value = 52000, tier = 'értékes', crateStyle = 'green' },
            { name = 'ekszeres_ladika',           label = 'Ékszeres ládika',           weight = 1600, chance = 20, min = 1, max = 1, value = 76000, tier = 'ritka', crateStyle = 'blue' },
            { name = 'fekete_piac_csomag',        label = 'Fekete piaci csomag',       weight = 2200, chance = 8,  min = 1, max = 1, value = 110000, tier = 'nagyon ritka', crateStyle = 'rare' }
        }
    },
    {
        id = 'chiliad_high',
        label = 'Mount Chiliad - ritka kincs lelőhely',
        areaName = 'Mount Chiliad',
        respawnMinutes = 45,
        polygon = {
            vector2(-80.0, 5080.0),
            vector2(470.0, 5600.0),
            vector2(480.0, 5590.0),
            vector2(430.0, 5550.0),
            vector2(-30.0, 5090.0),
            vector2(-90.0, 5070.0)
        },
        pointCount = 12,
        minZ = 370.0,
        maxZ = 790.0,
        minDistance = 35.0,
        rewards = {
            { name = 'aranyrog_tasak',       label = 'Aranyrög tasak',       weight = 900,  chance = 38, min = 1, max = 1, value = 65000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'gyemant_toredek',      label = 'Gyémánt töredék',      weight = 350,  chance = 30, min = 1, max = 1, value = 95000,  tier = 'ritka', crateStyle = 'blue' },
            { name = 'antik_szobor',         label = 'Antik szobor',         weight = 1800, chance = 22, min = 1, max = 1, value = 135000, tier = 'nagyon ritka', crateStyle = 'rare' },
            { name = 'elveszett_kincseslada', label = 'Elveszett kincsesláda', weight = 3500, chance = 10, min = 1, max = 1, value = 210000, tier = 'legendás', crateStyle = 'gold' }
        }
    },
    {
        id = 'ls_docks_smuggler',
        label = 'Los Santos kikötő - csempész rakomány',
        areaName = 'Los Santos Docks',
        respawnMinutes = 38,
        polygon = {
            vector2(810.0, -2970.0),
            vector2(900.0, -2970.0),
            vector2(1300.0, -3440.0),
            vector2(1240.0, -3440.0),
            vector2(830.0, -3020.0)
        },
        pointCount = 10,
        minZ = 4.0,
        maxZ = 6.0,
        minDistance = 20.0,
        rewards = {
            { name = 'csempesz_csomag',        label = 'Csempész csomag',        weight = 1800, chance = 42, min = 1, max = 1, value = 38000,  tier = 'közepes', crateStyle = 'white' },
            { name = 'elektronikai_lada',      label = 'Elektronikai láda',      weight = 2500, chance = 30, min = 1, max = 1, value = 68000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'titkositott_adattarolo', label = 'Titkosított adattároló', weight = 400,  chance = 20, min = 1, max = 1, value = 98000,  tier = 'ritka', crateStyle = 'blue' },
            { name = 'premium_csempesz_lada',  label = 'Prémium csempész láda', weight = 3200, chance = 8,  min = 1, max = 1, value = 165000, tier = 'nagyon ritka', crateStyle = 'rare' }
        }
    }
}

-- Régi verzióval való kompatibilitás: ha valaki még points-ot használ egy zónában,
-- az is működik. A polygon mód elsőbbséget élvez ha mindkettő definiálva van.
Config.Rewards = Config.DetectorZones[1].rewards
Config.DetectorPoints = {}

Config.Text = {
    detectorOn = 'Elővetted és bekapcsoltad a fémdetektort.',
    detectorOff = 'Elraktad a fémdetektort.',
    noDetector = 'Nincs nálad fémkereső.',
    noShovel = 'Nincs nálad ásó.',
    tooFar = 'Túl messze vagy a jelzett ponttól.',
    pointBusy = 'Ezt a pontot épp valaki más ássa.',
    digPrompt = '~y~[E]~s~ Ásás megkezdése',
    pickupPrompt = '~y~[E]~s~ Láda felvétele',
    digging = 'Ásás folyamatban...',
    cancelled = 'Megszakítottad az ásást.',
    crateFound = 'Találtál egy ládát. Vedd fel a földről!',
    cratePicked = 'Felvetted a ládát.',
    inventoryFull = 'Nincs elég hely az inventorydban.',
    noSignal = 'Nincs jel a közelben.',
    zoneEntered = 'Detektorozható terület: %s'
}
