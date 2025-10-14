---------------------------------------
----  Creación de la Base de Datos
USE master
GO

CREATE DATABASE AltosDelValle
ON PRIMARY (
    NAME = 'AltosDelValle_Data',
    FILENAME = '/var/opt/mssql/data/AltosDelValle_Data.mdf',
    SIZE = 1024MB,
    MAXSIZE = 6000MB,    
    FILEGROWTH = 128MB   
)
LOG ON (
    NAME = 'AltosDelValle_Log',
    FILENAME = '/var/opt/mssql/log/AltosDelValle_Log.ldf',
    SIZE = 512MB,        
    MAXSIZE = 3000MB,    
    FILEGROWTH = 128MB
)
GO
  
--------------------------------
-----------Crear FileGroups
USE master
GO

ALTER DATABASE AltosDelValle
ADD FILEGROUP Clientes
GO

ALTER DATABASE AltosDelValle
ADD FILEGROUP Propiedades
GO

ALTER DATABASE AltosDelValle
ADD FILEGROUP Contratos
GO

ALTER DATABASE AltosDelValle
ADD FILEGROUP Facturas
GO

-------------------------------------
---- Tamaños de FileGroups
USE master
GO

-- Filegroup Clientes
ALTER DATABASE AltosDelValle
ADD FILE (
    NAME = 'Clientes_Data',
    FILENAME = '/var/opt/mssql/data/Clientes_Data.ndf',
    SIZE = 500MB,
    MAXSIZE = 1500MB,
    FILEGROWTH = 100MB
) TO FILEGROUP Clientes
GO

-- Filegroup Propiedades
ALTER DATABASE AltosDelValle
ADD FILE (
    NAME = 'Propiedades_Data',
    FILENAME = '/var/opt/mssql/data/Propiedades_Data.ndf',
    SIZE = 500MB,
    MAXSIZE = 1500MB,
    FILEGROWTH = 100MB
) TO FILEGROUP Propiedades
GO

-- Filegroup Contratos
ALTER DATABASE AltosDelValle
ADD FILE (
    NAME = 'Contratos_Data',
    FILENAME = '/var/opt/mssql/data/Contratos_Data.ndf',
    SIZE = 1000MB,
    MAXSIZE = 2000MB,
    FILEGROWTH = 200MB
) TO FILEGROUP Contratos
GO

-- Filegroup Facturas
ALTER DATABASE AltosDelValle
ADD FILE (
    NAME = 'Facturas_Data',
    FILENAME = '/var/opt/mssql/data/Facturas_Data.ndf',
    SIZE = 1000MB,
    MAXSIZE = 2000MB,
    FILEGROWTH = 200MB
) TO FILEGROUP Facturas
GO
