
USE AltosDelValle
GO

--			TABLA PROPIEDAD
CREATE TABLE Propiedad (
    idPropiedad INT IDENTITY(1,1) PRIMARY KEY,
    ubicacion VARCHAR(100) NOT NULL,
    precio MONEY NOT NULL,
    idEstado INT NOT NULL,
    idTipoInmueble INT NOT NULL,
    identificacion INT NOT NULL
    -- Foreign keys
    CONSTRAINT FK_Propiedad_EstadoPropiedad FOREIGN KEY (idEstado) REFERENCES EstadoPropiedad(idEstado),
    CONSTRAINT FK_Propiedad_TipoInmueble FOREIGN KEY (idTipoInmueble) REFERENCES TipoInmueble(idTipoInmueble),
    CONSTRAINT FK_Identificacion_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion)
);
GO

-- agregamos validaciones

-- ALTER TABLE Propiedad
-- ADD CONSTRAINT CHK_Propiedad_Precio_Pos
-- CHECK (precio > 0);
-- GO

-- ALTER TABLE Propiedad
-- ADD CONSTRAINT CHK_Propiedad_Ubicacion_Longitud
-- CHECK (LEN(ubicacion) >= 5);
-- GO


-- final 
