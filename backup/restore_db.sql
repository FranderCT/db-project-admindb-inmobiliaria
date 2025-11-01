RESTORE VERIFYONLY 
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251101_191633.bak'
WITH CHECKSUM; -- verifica integridad del backup


RESTORE DATABASE AltosDelValle
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251101_191633.bak'
WITH 
    REPLACE,   
    RECOVERY,   
    STATS = 10; 
GO -- realiza la restauración

