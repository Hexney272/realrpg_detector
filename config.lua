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
    cancel = 73     -- X
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
-- value = becsült érték, ami metadata-ba és láda feliratba kerül. A tényleges eladási árhoz a saját shop/sell scriptedben használd az item nevét vagy a metadata.estimatedValue értéket.
Config.DetectorZones = {
    {
        id = 'cayo_drog',
        label = 'Cayo Perico - illegális alapanyag lelőhely',
        areaName = 'Cayo Perico',
        respawnMinutes = 35,
        rewards = {
            { name = 'drog_alapanyag_lada',       label = 'Drog alapanyag láda',       weight = 3000, chance = 55, min = 1, max = 1, value = 45000,  tier = 'közepes', crateStyle = 'white' },
            { name = 'drog_alapanyag_lada_zold',  label = 'Zöld drog alapanyag láda',  weight = 3000, chance = 25, min = 1, max = 1, value = 75000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'drog_alapanyag_lada_kek',   label = 'Kék drog alapanyag láda',   weight = 3000, chance = 14, min = 1, max = 1, value = 120000, tier = 'ritka', crateStyle = 'blue' },
            { name = 'ritka_drog_alapanyag_lada', label = 'Ritka drog alapanyag láda', weight = 3000, chance = 6,  min = 1, max = 1, value = 220000, tier = 'nagyon ritka', crateStyle = 'rare' }
        },
        points = {
            vector3(4506.21, -4521.83, 4.18),
            vector3(4538.45, -4490.12, 6.25),
            vector3(4571.74, -4468.66, 8.91),
            vector3(4610.12, -4516.88, 12.12),
            vector3(4646.38, -4551.34, 13.74),
            vector3(4685.70, -4590.31, 15.30),
            vector3(4724.84, -4630.61, 18.84),
            vector3(4762.92, -4668.44, 20.55),
            vector3(4805.06, -4701.29, 22.20),
            vector3(4850.88, -4728.73, 22.90),
            vector3(4894.72, -4758.45, 20.42),
            vector3(4936.51, -4794.08, 18.35),
            vector3(4975.72, -4829.29, 16.60),
            vector3(5015.90, -4868.44, 14.18),
            vector3(5060.24, -4907.13, 12.55),
            vector3(5108.30, -4942.82, 10.81),
            vector3(5150.57, -4977.45, 9.45),
            vector3(5192.94, -5015.71, 7.80),
            vector3(5236.18, -5057.16, 6.20),
            vector3(5281.66, -5100.53, 4.60)
        }
    },
    {
        id = 'grand_senora_low',
        label = 'Grand Senora - olcsó roncs lelőhely',
        areaName = 'Grand Senora Desert',
        respawnMinutes = 22,
        rewards = {
            { name = 'rozsdas_femdarab',     label = 'Rozsdás fémdarab',          weight = 800,  chance = 48, min = 1, max = 3, value = 2500,  tier = 'olcsó', crateStyle = 'white' },
            { name = 'regi_erme',            label = 'Régi érme',                 weight = 100,  chance = 30, min = 1, max = 2, value = 8500,  tier = 'olcsó', crateStyle = 'white' },
            { name = 'katonai_alkatresz',    label = 'Régi katonai alkatrész',    weight = 1200, chance = 17, min = 1, max = 1, value = 18000, tier = 'közepes', crateStyle = 'green' },
            { name = 'arany_karora',         label = 'Elásott arany karóra',      weight = 250,  chance = 5,  min = 1, max = 1, value = 42000, tier = 'ritka', crateStyle = 'rare' }
        },
        points = {
            vector3(1519.28, 3086.63, 40.52),
            vector3(1562.76, 3130.14, 41.22),
            vector3(1615.83, 3181.55, 40.71),
            vector3(1668.19, 3237.44, 40.62),
            vector3(1719.71, 3291.84, 40.93),
            vector3(1768.35, 3347.68, 40.22),
            vector3(1822.67, 3402.45, 39.84),
            vector3(1875.09, 3454.22, 39.27),
            vector3(1927.35, 3507.11, 38.82),
            vector3(1980.12, 3564.93, 38.11),
            vector3(2034.55, 3621.44, 37.51),
            vector3(2089.82, 3679.18, 36.94),
            vector3(2144.28, 3734.52, 36.41),
            vector3(2198.31, 3787.90, 35.74),
            vector3(2254.84, 3841.36, 35.09),
            vector3(2312.06, 3898.20, 34.64)
        }
    },
    {
        id = 'paleto_forest_mid',
        label = 'Paleto erdő - elrejtett csomagok',
        areaName = 'Paleto Forest',
        respawnMinutes = 30,
        rewards = {
            { name = 'elrejtett_keszpenz_csomag', label = 'Elrejtett készpénz csomag', weight = 600,  chance = 42, min = 1, max = 1, value = 28000, tier = 'közepes', crateStyle = 'white' },
            { name = 'hamis_okmany_taska',        label = 'Hamis okmány táska',        weight = 1200, chance = 30, min = 1, max = 1, value = 52000, tier = 'értékes', crateStyle = 'green' },
            { name = 'ekszeres_ladika',           label = 'Ékszeres ládika',           weight = 1600, chance = 20, min = 1, max = 1, value = 76000, tier = 'ritka', crateStyle = 'blue' },
            { name = 'fekete_piac_csomag',        label = 'Fekete piaci csomag',       weight = 2200, chance = 8,  min = 1, max = 1, value = 110000, tier = 'nagyon ritka', crateStyle = 'rare' }
        },
        points = {
            vector3(-515.39, 5375.21, 70.34),
            vector3(-553.62, 5429.86, 66.18),
            vector3(-603.14, 5486.77, 58.42),
            vector3(-646.32, 5534.18, 48.75),
            vector3(-689.74, 5585.63, 38.62),
            vector3(-735.28, 5638.79, 31.35),
            vector3(-780.42, 5689.34, 24.92),
            vector3(-824.63, 5741.15, 19.85),
            vector3(-869.11, 5793.92, 15.40),
            vector3(-914.55, 5844.37, 12.64),
            vector3(-958.21, 5895.83, 9.86),
            vector3(-1005.72, 5948.60, 6.94),
            vector3(-1049.18, 5997.24, 4.72),
            vector3(-1096.43, 6048.19, 3.86)
        }
    },
    {
        id = 'chiliad_high',
        label = 'Mount Chiliad - ritka kincs lelőhely',
        areaName = 'Mount Chiliad',
        respawnMinutes = 45,
        rewards = {
            { name = 'aranyrog_tasak',       label = 'Aranyrög tasak',       weight = 900,  chance = 38, min = 1, max = 1, value = 65000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'gyemant_toredek',      label = 'Gyémánt töredék',      weight = 350,  chance = 30, min = 1, max = 1, value = 95000,  tier = 'ritka', crateStyle = 'blue' },
            { name = 'antik_szobor',         label = 'Antik szobor',         weight = 1800, chance = 22, min = 1, max = 1, value = 135000, tier = 'nagyon ritka', crateStyle = 'rare' },
            { name = 'elveszett_kincseslada', label = 'Elveszett kincsesláda', weight = 3500, chance = 10, min = 1, max = 1, value = 210000, tier = 'legendás', crateStyle = 'gold' }
        },
        points = {
            vector3(449.94, 5572.14, 781.18),
            vector3(401.72, 5534.78, 763.45),
            vector3(352.13, 5491.52, 742.33),
            vector3(303.48, 5448.23, 714.60),
            vector3(255.86, 5402.40, 681.94),
            vector3(210.12, 5357.91, 646.22),
            vector3(163.64, 5315.28, 606.87),
            vector3(118.33, 5274.14, 563.44),
            vector3(72.82, 5231.57, 518.20),
            vector3(28.44, 5190.63, 471.75),
            vector3(-16.38, 5148.30, 424.82),
            vector3(-62.71, 5106.15, 379.10)
        }
    },
    {
        id = 'ls_docks_smuggler',
        label = 'Los Santos kikötő - csempész rakomány',
        areaName = 'Los Santos Docks',
        respawnMinutes = 38,
        rewards = {
            { name = 'csempesz_csomag',        label = 'Csempész csomag',        weight = 1800, chance = 42, min = 1, max = 1, value = 38000,  tier = 'közepes', crateStyle = 'white' },
            { name = 'elektronikai_lada',      label = 'Elektronikai láda',      weight = 2500, chance = 30, min = 1, max = 1, value = 68000,  tier = 'értékes', crateStyle = 'green' },
            { name = 'titkositott_adattarolo', label = 'Titkosított adattároló', weight = 400,  chance = 20, min = 1, max = 1, value = 98000,  tier = 'ritka', crateStyle = 'blue' },
            { name = 'premium_csempesz_lada',  label = 'Prémium csempész láda', weight = 3200, chance = 8,  min = 1, max = 1, value = 165000, tier = 'nagyon ritka', crateStyle = 'rare' }
        },
        points = {
            vector3(834.38, -2996.28, 5.02),
            vector3(882.14, -3040.56, 5.11),
            vector3(930.66, -3087.19, 5.10),
            vector3(979.51, -3131.68, 5.20),
            vector3(1027.24, -3179.33, 5.27),
            vector3(1075.82, -3224.76, 5.24),
            vector3(1124.44, -3272.81, 5.20),
            vector3(1171.94, -3318.48, 5.18),
            vector3(1220.63, -3364.95, 5.16),
            vector3(1268.72, -3411.08, 5.17)
        }
    }
}

-- Régi verzióval való kompatibilitás miatt meghagyott fallback jutalom.
-- Ha Config.DetectorZones ki van töltve, ezt már nem használja a script.
Config.Rewards = Config.DetectorZones[1].rewards
Config.DetectorPoints = Config.DetectorZones[1].points

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
