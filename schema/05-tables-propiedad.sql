USE AltosDelValle;
GO

-- PROPIEDAD
CREATE TABLE Propiedad (
    idPropiedad int  PRIMARY KEY,
    ubicacion VARCHAR(100) NOT NULL,
    precio MONEY NOT NULL,
    idEstado INT NOT NULL,
    idTipoInmueble INT NOT NULL,
    identificacion INT NOT NULL,
	imagenUrl NVARCHAR(500) NULL,
    cantBannios int NOT NULL,
    areaM2 FLOAT NOT NULL,
    amueblado bit NOT NULL,
    cantHabitaciones int NOT NULL
) ON Propiedades;
GO


alter table Propiedad
add CONSTRAINT CHK_Propiedad_CantHabitaciones_Valid CHECK (cantHabitaciones > 0);
GO

alter table Propiedad
add CONSTRAINT CHK_Propiedad_CantBannios_Valid CHECK (cantBannios > 0);
GO

alter table Propiedad
add CONSTRAINT CHK_Propiedad_AreaM2_Valid CHECK (areaM2 > 0);
GO

-- FK + CHECKS
ALTER TABLE Propiedad
ADD CONSTRAINT FK_Propiedad_EstadoPropiedad 
FOREIGN KEY (idEstado) REFERENCES EstadoPropiedad(idEstadoPropiedad);

ALTER TABLE Propiedad
ADD CONSTRAINT FK_Propiedad_TipoInmueble 
FOREIGN KEY (idTipoInmueble) REFERENCES TipoInmueble(idTipoInmueble);

ALTER TABLE Propiedad
ADD CONSTRAINT FK_Identificacion_Cliente 
FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion);

ALTER TABLE Propiedad
ADD CONSTRAINT CHK_Propiedad_IdEstado_Valid CHECK (idEstado > 0);

ALTER TABLE Propiedad
ADD CONSTRAINT CHK_Propiedad_IdTipoInmueble_Valid CHECK (idTipoInmueble > 0);

ALTER TABLE Propiedad
ADD CONSTRAINT CHK_Propiedad_Identificacion_Valid CHECK (identificacion > 0);

ALTER TABLE Propiedad
ADD CONSTRAINT CHK_Propiedad_Precio_Pos CHECK (precio > 0);

ALTER TABLE Propiedad
ADD CONSTRAINT CHK_Propiedad_Ubicacion_Longitud CHECK (LEN(ubicacion) >= 5);
GO


select * from Propiedad;