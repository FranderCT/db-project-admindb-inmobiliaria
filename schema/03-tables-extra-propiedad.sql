use AltosDelValle
go

-- ESTADO PROPIEDAD
CREATE TABLE EstadoPropiedad (
    idEstadoPropiedad INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
GO

-- TABLA TIPO INMUEBLE
CREATE TABLE TipoInmueble (
    idTipoInmueble INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
)
GO