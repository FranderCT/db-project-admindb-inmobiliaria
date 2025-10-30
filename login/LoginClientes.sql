USE master;
GO

CREATE LOGIN adminAltosDelValle 
WITH PASSWORD = 'Frander123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
GO

USE AltosDelValle;
GO

CREATE USER adminAltosDelValle FOR LOGIN adminAltosDelValle;
GO

GRANT EXECUTE ON SCHEMA::dbo TO adminAltosDelValle;
GO

GRANT SELECT ON SCHEMA::dbo TO adminAltosDelValle;
GO

GRANT EXECUTE ON SCHEMA::dbo TO adminAltosDelValle;
GO

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO adminAltosDelValle;
GO
