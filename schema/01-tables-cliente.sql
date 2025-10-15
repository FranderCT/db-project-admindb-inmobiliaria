--			TABLA CLIENTE
USE AltosDelValle
GO
CREATE TABLE Cliente (
    identificacion INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    apellido1 VARCHAR(30) NOT NULL,
    apellido2 VARCHAR(30) NULL,
    telefono VARCHAR(30) NOT NULL,
    estado BIT NOT NULL DEFAULT 1
)
GO

-- TABLA TIPO ROL
CREATE TABLE TipoRol (
    idRol INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
)
GO