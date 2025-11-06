

USE master;
GO

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'adminAltosDelValle')
BEGIN
    CREATE LOGIN adminAltosDelValle
    WITH PASSWORD = 'Frander123!',
        CHECK_POLICY = ON,
        CHECK_EXPIRATION = OFF;
END
GO

USE AltosDelValle;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'adminAltosDelValle')
BEGIN
    CREATE USER adminAltosDelValle FOR LOGIN adminAltosDelValle;
END
GO

ALTER ROLE db_datareader ADD MEMBER adminAltosDelValle;
ALTER ROLE db_datawriter ADD MEMBER adminAltosDelValle;
GRANT EXECUTE ON SCHEMA::dbo TO adminAltosDelValle;
GO


USE DataMartAltosDelValle;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'adminAltosDelValle')
BEGIN
    CREATE USER adminAltosDelValle FOR LOGIN adminAltosDelValle;
END
GO

ALTER ROLE db_datareader ADD MEMBER adminAltosDelValle;
ALTER ROLE db_datawriter ADD MEMBER adminAltosDelValle;
GRANT EXECUTE ON SCHEMA::dbo TO adminAltosDelValle;
GO


USE AltosDelValle;
GO
ALTER DATABASE AltosDelValle SET TRUSTWORTHY ON;
GO
ALTER AUTHORIZATION ON DATABASE::AltosDelValle TO sa;
GO


USE DataMartAltosDelValle;
GO
SELECT name AS Usuario, type_desc AS Tipo, authentication_type_desc AS Autenticacion
FROM sys.database_principals
WHERE name = 'adminAltosDelValle';
GO

USE AltosDelValle;
GO
SELECT name AS Usuario, type_desc AS Tipo, authentication_type_desc AS Autenticacion
FROM sys.database_principals
WHERE name = 'adminAltosDelValle';
GO
