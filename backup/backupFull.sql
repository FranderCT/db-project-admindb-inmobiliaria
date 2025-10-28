DECLARE @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112);
DECLARE @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
DECLARE @dest NVARCHAR(4000) = N'/var/opt/mssql/backups/AltosDelValle/AltosDelValle_FULL_' 
                                + @fecha + '_' + @hora + N'.bak';

BACKUP DATABASE AltosDelValle
TO DISK = @dest
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10;

-- Verificación rápida (opcional pero recomendable)
RESTORE VERIFYONLY FROM DISK = @dest;
--guarda toda la base de datos en su estado actual.
