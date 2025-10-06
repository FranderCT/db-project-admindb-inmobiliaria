--			TABLA PROPIEDAD
USE AltosDelValle
GO

CREATE TABLE Propiedad (
    Id_propiedad INT IDENTITY(1,1) PRIMARY KEY,
    Ubicacion VARCHAR(255) NOT NULL,
    Precio FLOAT NOT NULL,
    Estado VARCHAR(25) NOT NULL, -- disponible, reservada, mantenimiento
    Cedula_Cliente VARCHAR(20) NOT NULL, -- foreign key de cliente 
    CONSTRAINT FK_CEDULA_CILENTE FOREIGN KEY(Cedula_Cliente) REFERENCES Ciente(Cedula)
);
GO

--			TABLA TIPO INMUEBLE
USE AltosDelValle
GO

CREATE TABLE Tipo_Inmbueble(
    Id_TipoInmueble INT IDENTITY(1,1) PRIMARY KEY,
    Nombre_Inmueble VARCHAR(50) NOT NULL
);
GO

--			TABLA ESTADO PROPIEDAD