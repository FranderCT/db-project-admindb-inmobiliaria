USE master;
GO

DECLARE 
    @DBName SYSNAME = N'AltosDelValle', -- elegir la base de datos a respaldar
    @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112), -- la fecha en formato YYYYMMDD
    @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', ''), -- la hora en formato HHMMSS
    @path NVARCHAR(4000); -- ruta completa del archivo de respaldo

SET @path = N'/var/opt/mssql/data/AltosDelValle_Backups/' + @DBName + '_' + @fecha + '_' + @hora + '.bak'; -- construir la ruta completa

BACKUP DATABASE @DBName
TO DISK = @path
WITH 
    FORMAT,                 -- Crea un nuevo conjunto de backup
    INIT,                   -- Sobrescribe el archivo si existe
    COMPRESSION,            -- Comprime el respaldo
    CHECKSUM,               -- Verifica integridad
    COPY_ONLY,              -- No interfiere con backups diferenciales
    STATS = 10;
GO
