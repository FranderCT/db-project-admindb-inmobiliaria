USE msdb;
GO


IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'Backup_AltosDelValle_Hourly')
BEGIN
    EXEC msdb.dbo.sp_delete_job 
        @job_name = N'Backup_AltosDelValle_Hourly',
        @delete_unused_schedule = 1;
    
    PRINT 'Job existente eliminado';
END
GO


DECLARE @jobId BINARY(16);

EXEC msdb.dbo.sp_add_job
    @job_name = N'Backup_AltosDelValle_Hourly',
    @enabled = 1,
    @description = N'Respaldo automático cada hora de la base de datos AltosDelValle',
    @category_name = N'Database Maintenance',
    @owner_login_name = N'sa',
    @job_id = @jobId OUTPUT;

EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Backup_AltosDelValle_Hourly',
    @step_name = N'Ejecutar Backup Comprimido',
    @step_id = 1,
    @subsystem = N'TSQL',
    @command = N'
        DECLARE 
            @DBName SYSNAME = N''AltosDelValle'',
            @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112),
            @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), '':'', ''''),
            @path NVARCHAR(4000);

        SET @path = N''/var/opt/mssql/data/AltosDelValle_Backups/'' + @DBName + ''_'' + @fecha + ''_'' + @hora + ''.bak'';

        BACKUP DATABASE @DBName
        TO DISK = @path
        WITH 
            FORMAT,
            INIT,
            COMPRESSION,
            CHECKSUM,
            COPY_ONLY,
            STATS = 10;
        
        PRINT ''Backup completado: '' + @path;
    ',
    @database_name = N'master',
    @retry_attempts = 3,
    @retry_interval = 5,
    @on_success_action = 1,
    @on_fail_action = 2;

EXEC msdb.dbo.sp_add_schedule
    @schedule_name = N'Cada_Hora_AltosDelValle',
    @enabled = 1,
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 8,
    @freq_subday_interval = 1,
    @active_start_time = 000000;

EXEC msdb.dbo.sp_attach_schedule
    @job_name = N'Backup_AltosDelValle_Hourly',
    @schedule_name = N'Cada_Hora_AltosDelValle';

EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Backup_AltosDelValle_Hourly',
    @server_name = N'(local)';

PRINT 'Job "Backup_AltosDelValle_Hourly" recreado exitosamente';
PRINT 'Ejecutará backups cada hora';
GO





-- Verificar el estado del agente
EXEC master.dbo.xp_servicecontrol N'QueryState', N'SQLServerAgent';

-- Ver si hay jobs activos
SELECT 
    name AS JobName,
    enabled AS IsEnabled,
    date_created,
    date_modified
FROM msdb.dbo.sysjobs
WHERE name = 'Backup_AltosDelValle_Hourly';


USE master;
GO

-- Ejecutar el backup directamente
DECLARE 
    @DBName SYSNAME = N'AltosDelValle',
    @fecha VARCHAR(8) = CONVERT(VARCHAR(8), GETDATE(), 112),
    @hora VARCHAR(6) = REPLACE(CONVERT(VARCHAR(8), GETDATE(), 108), ':', ''),
    @path NVARCHAR(4000);

SET @path = N'/var/opt/mssql/data/AltosDelValle_Backups/' + @DBName + '_' + @fecha + '_' + @hora + '.bak';

BACKUP DATABASE @DBName
TO DISK = @path
WITH 
    FORMAT,
    INIT,
    COMPRESSION,
    CHECKSUM,
    COPY_ONLY,
    STATS = 10;

PRINT 'Backup completado: ' + @path;







