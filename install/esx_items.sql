-- Csak akkor kell, ha NEM ox_inventory item definíciót használsz.
-- ESX Legacy alap items táblához.

INSERT INTO `items` (`name`, `label`, `weight`, `rare`, `can_remove`) VALUES
('femkereso', 'Fémkereső', 1500, 0, 1),
('aso', 'Ásó', 1000, 0, 1),
('drog_alapanyag_lada', 'Drog alapanyag láda', 3000, 0, 1),
('drog_alapanyag_lada_zold', 'Zöld drog alapanyag láda', 3000, 0, 1),
('drog_alapanyag_lada_kek', 'Kék drog alapanyag láda', 3000, 0, 1),
('ritka_drog_alapanyag_lada', 'Ritka drog alapanyag láda', 3000, 0, 1),
('rozsdas_femdarab', 'Rozsdás fémdarab', 800, 0, 1),
('regi_erme', 'Régi érme', 100, 0, 1),
('katonai_alkatresz', 'Régi katonai alkatrész', 1200, 0, 1),
('arany_karora', 'Elásott arany karóra', 250, 0, 1),
('elrejtett_keszpenz_csomag', 'Elrejtett készpénz csomag', 600, 0, 1),
('hamis_okmany_taska', 'Hamis okmány táska', 1200, 0, 1),
('ekszeres_ladika', 'Ékszeres ládika', 1600, 0, 1),
('fekete_piac_csomag', 'Fekete piaci csomag', 2200, 0, 1),
('aranyrog_tasak', 'Aranyrög tasak', 900, 0, 1),
('gyemant_toredek', 'Gyémánt töredék', 350, 0, 1),
('antik_szobor', 'Antik szobor', 1800, 0, 1),
('elveszett_kincseslada', 'Elveszett kincsesláda', 3500, 0, 1),
('csempesz_csomag', 'Csempész csomag', 1800, 0, 1),
('elektronikai_lada', 'Elektronikai láda', 2500, 0, 1),
('titkositott_adattarolo', 'Titkosított adattároló', 400, 0, 1),
('premium_csempesz_lada', 'Prémium csempész láda', 3200, 0, 1)
ON DUPLICATE KEY UPDATE `label` = VALUES(`label`), `weight` = VALUES(`weight`), `can_remove` = VALUES(`can_remove`);
