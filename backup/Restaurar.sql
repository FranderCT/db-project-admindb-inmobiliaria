-- 1️ Restaurar FULL
RESTORE DATABASE AltosDelValle
FROM DISK = '/var/opt/mssql/backups/AltosDelValle/AltosDelValle_FULL_20251027_140000.bak'
WITH NORECOVERY, REPLACE;

-- 2️ Restaurar DIFERENCIAL 
RESTORE DATABASE AltosDelValle
FROM DISK = '/var/opt/mssql/backups/AltosDelValle/AltosDelValle_DIFF_20251027_160000.bak'
WITH NORECOVERY;

-- 3️ Restaurar LOG 
RESTORE LOG AltosDelValle
FROM DISK = '/var/opt/mssql/backups/AltosDelValle/AltosDelValle_LOG_20251027_163000.trn'
WITH RECOVERY;


-- solo para full
RESTORE DATABASE AltosDelValle
FROM DISK = '/var/opt/mssql/backups/AltosDelValle/AltosDelValle_FULL_20251027_140000.bak'
WITH REPLACE, RECOVERY;
