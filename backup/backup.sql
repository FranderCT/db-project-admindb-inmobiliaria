USE master;
GO

DECLARE 
    @DBName SYSNAME = N'AltosDelValle',
    @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112),
    @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', ''),
    @path NVARCHAR(4000);

SET @path = N'/var/opt/mssql/data/AltosDelValle_Backups/' + @DBName + '_' + @fecha + '_' + @hora + '.bak';

PRINT '📦 Iniciando respaldo completo de la base: ' + @DBName;
PRINT 'Ruta destino: ' + @path;

BACKUP DATABASE @DBName
TO DISK = @path
WITH 
    FORMAT,                 -- Crea un nuevo conjunto de backup
    INIT,                   -- Sobrescribe el archivo si existe
    COMPRESSION,            -- Comprime el respaldo
    CHECKSUM,               -- Verifica integridad
    COPY_ONLY,              -- No interfiere con backups diferenciales
    STATS = 10;



RESTORE VERIFYONLY 
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251101_180837.bak'
WITH CHECKSUM;


USE master;
GO

RESTORE DATABASE AltosDelValle
FROM DISK = N'/var/opt/mssql/data/AltosDelValle_Backups/AltosDelValle_20251101_180837.bak'
WITH 
    REPLACE,   
    RECOVERY,   
    STATS = 10; 
GO

