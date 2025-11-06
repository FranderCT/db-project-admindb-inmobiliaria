RESTORE VERIFYONLY 
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251105_214744.bak'
WITH CHECKSUM; -- verifica integridad del backup


RESTORE DATABASE AltosDelValle
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251105_214744.bak'
WITH 
    REPLACE,   
    RECOVERY,   
    STATS = 10; 
GO -- realiza la restauración

