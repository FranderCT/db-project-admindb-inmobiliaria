CREATE TABLE Cliente (
    Cedula VARCHAR(20) NOT NULL PRIMARY KEY,
    Nombre VARCHAR(40) NOT NULL,
    Apellido1 VARCHAR(30) NOT NULL,
    Apellido2 VARCHAR(30) NOT NULL,
    Telefono VARCHAR(20) NOT NULL
);
GO
--  TABLA CLIENTES

-- TIPOS Y ROLES

CREATE TABLE Tipo_Inmbueble(
    Id_TipoInmueble INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Inmueble VARCHAR(50) NOT NULL
);
GO
--  TABLA INMUEBLES

CREATE TABLE TIpo_RolUsuario(
    Id_RolUsuario INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_rol VARCHAR(30) NOT NULL
);
GO

-- TIPOS Y ROLES

CREATE TABLE Propiedad (
    Id_propiedad INT IDENTITY(1,1) PRIMARY KEY,
    Ubicacion VARCHAR(255) NOT NULL,
    Precio FLOAT NOT NULL,
    Estado VARCHAR(25) NOT NULL, -- disponible, reservada, mantenimiento
    Cedula_Cliente VARCHAR(20) NOT NULL, -- foreign key de cliente 
    CONSTRAINT FK_CEDULA_CILENTE FOREIGN KEY(Cedula_Cliente) REFERENCES Ciente(Cedula)
);
GO
-- TABLA PROPIEDADES

