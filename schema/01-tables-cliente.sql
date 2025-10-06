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

--			TIPOS Y ROLES
USE AltosDelValle
GO
CREATE TABLE Tipo_RolUsuario(
    Id_RolUsuario INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_rol VARCHAR(30) NOT NULL
);
GO


--			TABLA CLIENTECONTRATO