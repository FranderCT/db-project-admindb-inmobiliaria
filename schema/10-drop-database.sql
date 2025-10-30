ALTER DATABASE AltosDelValle 
SET SINGLE_USER 
WITH ROLLBACK IMMEDIATE;

DROP DATABASE AltosDelValle;

USE master;
GO
DROP DATABASE AltosDelValle;

SELECT name 
FROM sys.databases;





USE master;
GO

-- Ver existencia y estado
SELECT name, state_desc 
FROM sys.databases 
WHERE name = N'AltosDelValle';

-- Drop condicional (solo si existe)
IF DB_ID(N'AltosDelValle') IS NOT NULL
BEGIN
    ALTER DATABASE [AltosDelValle] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [AltosDelValle];
    PRINT 'AltosDelValle eliminada.';
END
ELSE
BEGIN
    PRINT 'AltosDelValle no existe.';
END
