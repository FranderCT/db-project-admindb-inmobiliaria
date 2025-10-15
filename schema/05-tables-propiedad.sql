use AltosDelValle
go

-- PROPIEDAD
CREATE TABLE Propiedad (
    idPropiedad INT IDENTITY(1,1) PRIMARY KEY,
    ubicacion VARCHAR(100) NOT NULL,
    precio MONEY NOT NULL,
    idEstado INT NOT NULL,
    idTipoInmueble INT NOT NULL,
    identificacion INT NOT NULL
) ON Propiedades;
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