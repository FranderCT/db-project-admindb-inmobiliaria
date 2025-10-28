DECLARE @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112);
DECLARE @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', '');
DECLARE @dest NVARCHAR(4000) = N'/var/opt/mssql/data/' 
                                + @fecha + '_' + @hora + N'.bak';

BACKUP DATABASE AltosDelValle
TO DISK = @dest
WITH DIFFERENTIAL, INIT, COMPRESSION, CHECKSUM, STATS = 10;

RESTORE VERIFYONLY FROM DISK = @dest;
-- Solo respalda lo que ha cambiado desde el último backup completo.