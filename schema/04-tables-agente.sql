--			TABLA AGENTE
USE AltosDelValle
GO

CREATE TABLE Agente (
    identificacion INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    apellido1 VARCHAR(30) NOT NULL,
    apellido2 VARCHAR(30) NULL,
    comisionAcumulada DECIMAL(18, 2) NOT NULL DEFAULT 0,
    estado BIT NOT NULL DEFAULT 1
)
go

