-- Ezt másold be az ox_inventory/data/items.lua fájlodba.
-- Ikonok: femkereso.png és aso.png megtalálható az install/web_images mappában.
-- A jutalom itemekhez adhatsz saját ikonokat ugyanilyen fájlnévvel az ox_inventory/web/images mappában.

['femkereso'] = {
    label = 'Fémkereső',
    weight = 1500,
    stack = false,
    close = true,
    consume = 0,
    description = 'Illegális alapanyag ládák és elrejtett leletek kereséséhez használható detektor.',
    client = {
        event = 'realrpg_detector:client:useDetectorItem'
    }
},

['aso'] = {
    label = 'Ásó',
    weight = 1000,
    stack = false,
    close = true,
    consume = 0,
    description = 'A detektorral talált pontok kiásásához szükséges.',
    client = {
        event = 'realrpg_detector:client:useShovelItem'
    }
},

-- Cayo Perico jutalmak
['drog_alapanyag_lada'] = {
    label = 'Drog alapanyag láda',
    weight = 3000,
    stack = true,
    close = true,
    description = 'Detektorozással talált illegális alapanyag láda.'
},

['drog_alapanyag_lada_zold'] = {
    label = 'Zöld drog alapanyag láda',
    weight = 3000,
    stack = true,
    close = true,
    description = 'Ritkább detektoros láda.'
},

['drog_alapanyag_lada_kek'] = {
    label = 'Kék drog alapanyag láda',
    weight = 3000,
    stack = true,
    close = true,
    description = 'Értékesebb detektoros láda.'
},

['ritka_drog_alapanyag_lada'] = {
    label = 'Ritka drog alapanyag láda',
    weight = 3000,
    stack = true,
    close = true,
    description = 'Nagyon ritka detektoros láda.'
},

-- Grand Senora jutalmak
['rozsdas_femdarab'] = {
    label = 'Rozsdás fémdarab',
    weight = 800,
    stack = true,
    close = true,
    description = 'Olcsó detektoros lelet.'
},

['regi_erme'] = {
    label = 'Régi érme',
    weight = 100,
    stack = true,
    close = true,
    description = 'Régi, földből előkerült érme.'
},

['katonai_alkatresz'] = {
    label = 'Régi katonai alkatrész',
    weight = 1200,
    stack = true,
    close = true,
    description = 'Közepes értékű detektoros lelet.'
},

['arany_karora'] = {
    label = 'Elásott arany karóra',
    weight = 250,
    stack = true,
    close = true,
    description = 'Ritka és értékes detektoros lelet.'
},

-- Paleto Forest jutalmak
['elrejtett_keszpenz_csomag'] = {
    label = 'Elrejtett készpénz csomag',
    weight = 600,
    stack = true,
    close = true,
    description = 'Elrejtett, gyanús eredetű csomag.'
},

['hamis_okmany_taska'] = {
    label = 'Hamis okmány táska',
    weight = 1200,
    stack = true,
    close = true,
    description = 'Fekete piacon értékesíthető táska.'
},

['ekszeres_ladika'] = {
    label = 'Ékszeres ládika',
    weight = 1600,
    stack = true,
    close = true,
    description = 'Értékes ékszereket tartalmazó ládika.'
},

['fekete_piac_csomag'] = {
    label = 'Fekete piaci csomag',
    weight = 2200,
    stack = true,
    close = true,
    description = 'Nagyon ritka detektoros fekete piaci csomag.'
},

-- Mount Chiliad jutalmak
['aranyrog_tasak'] = {
    label = 'Aranyrög tasak',
    weight = 900,
    stack = true,
    close = true,
    description = 'Értékes aranyrögöket tartalmazó tasak.'
},

['gyemant_toredek'] = {
    label = 'Gyémánt töredék',
    weight = 350,
    stack = true,
    close = true,
    description = 'Ritka gyémánt töredék.'
},

['antik_szobor'] = {
    label = 'Antik szobor',
    weight = 1800,
    stack = true,
    close = true,
    description = 'Nagy értékű antik lelet.'
},

['elveszett_kincseslada'] = {
    label = 'Elveszett kincsesláda',
    weight = 3500,
    stack = true,
    close = true,
    description = 'Legendás detektoros lelet.'
},

-- Los Santos Docks jutalmak
['csempesz_csomag'] = {
    label = 'Csempész csomag',
    weight = 1800,
    stack = true,
    close = true,
    description = 'Kikötő környékén elrejtett csempész csomag.'
},

['elektronikai_lada'] = {
    label = 'Elektronikai láda',
    weight = 2500,
    stack = true,
    close = true,
    description = 'Értékes elektronikai eszközöket tartalmazó láda.'
},

['titkositott_adattarolo'] = {
    label = 'Titkosított adattároló',
    weight = 400,
    stack = true,
    close = true,
    description = 'Titkosított adattároló, értékes információval.'
},

['premium_csempesz_lada'] = {
    label = 'Prémium csempész láda',
    weight = 3200,
    stack = true,
    close = true,
    description = 'Nagyon értékes kikötői csempész láda.'
},
