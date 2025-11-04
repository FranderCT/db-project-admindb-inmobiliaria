-- CREACION DE TODAS LAS TABLAS
use AltosDelValle
go

-- CLIENTE
CREATE TABLE Cliente (
    identificacion INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    apellido1 VARCHAR(30) NOT NULL,
    apellido2 VARCHAR(30) NULL,
    telefono VARCHAR(30) NOT NULL,
    estado BIT NOT NULL DEFAULT 1
);
GO

-- TIPO ROL
CREATE TABLE TipoRol (
    idRol INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
GO

-- TIPO CONTRATO
CREATE TABLE TipoContrato (
    idTipoContrato INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);
GO

-- TERMINOS CONDICIONES
CREATE TABLE TerminosCondiciones (
    idCondicion INT IDENTITY(1,1) PRIMARY KEY,
    textoCondicion VARCHAR(255) NOT NULL
);
GO

-- ESTADO PROPIEDAD
CREATE TABLE EstadoPropiedad (
    idEstadoPropiedad INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
GO

-- TIPO INMUEBLE
CREATE TABLE TipoInmueble (
    idTipoInmueble INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL
);
GO

-- AGENTE
CREATE TABLE Agente (
    identificacion INT PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL,
    apellido1 VARCHAR(30) NOT NULL,
    apellido2 VARCHAR(30) NULL,
    telefono VARCHAR(30) NOT NULL,
    comisionAcumulada DECIMAL(18, 2) NOT NULL DEFAULT 0,
    estado BIT NOT NULL DEFAULT 1
);
GO


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
--			TABLA CONTRATO
CREATE TABLE Contrato(
	idContrato int identity (1,1)PRIMARY KEY not null,
	fechaInicio DATETIME NULL, 
	fechaFin DATETIME NULL, 
	fechaFirma DATETIME NULL, 
	fechaPago DATETIME NULL,
	idTipoContrato INT NOT NULL,
	idPropiedad INT NOT NULL, 
	idAgente INT NOT NULL,
	montoTotal MONEY NULL,
  deposito MONEY NULL,
  porcentajeComision DECIMAL(5,2) NULL,
	cantidadPagos INT NULL, 
  estado NVARCHAR(30) DEFAULT 'Pendiente'
)ON Contratos
GO


-- FOREIGN KEYS
ALTER TABLE Contrato
ADD CONSTRAINT Fk_ContratoIdTipoContrato
FOREIGN KEY (idTipoContrato) REFERENCES TipoContrato(idTipoContrato);

ALTER TABLE Contrato
ADD CONSTRAINT Fk_ContratoIdPropiedad
FOREIGN KEY (idPropiedad) REFERENCES Propiedad(idPropiedad);

ALTER TABLE Contrato
ADD CONSTRAINT Fk_ContratoIdAgente
FOREIGN KEY (idAgente) REFERENCES Agente(identificacion);

-- CHECKS
ALTER TABLE Contrato 
ADD CONSTRAINT ck_ContratoFechasOrden
CHECK (fechaInicio IS NULL OR fechaFin IS NULL OR fechaInicio <= fechaFin);

ALTER TABLE Contrato 
ADD CONSTRAINT ck_ContratoFirmaEnRango
CHECK (
	fechaFirma IS NULL OR
	(
		(fechaInicio IS NULL OR fechaFirma >= fechaInicio) AND
		(fechaFin IS NULL OR fechaFirma <= fechaFin)
	)
);

ALTER TABLE Contrato 
ADD CONSTRAINT ck_ContratoPagoNoAntes
CHECK (
	fechaPago IS NULL OR
	(
		(fechaInicio IS NULL OR fechaPago >= fechaInicio) AND
		(fechaFirma  IS NULL OR fechaPago >= fechaFirma)
	)
);

ALTER TABLE Contrato 
ADD CONSTRAINT CK_Contrato_IdTipoContrato_Pos CHECK (idTipoContrato IS NULL OR idTipoContrato > 0);

ALTER TABLE Contrato 
ADD CONSTRAINT CK_Contrato_IdPropiedad_Pos CHECK (idPropiedad IS NULL OR idPropiedad > 0);

ALTER TABLE Contrato 
ADD CONSTRAINT CK_Contrato_IdAgente_Pos CHECK (idAgente IS NULL OR idAgente > 0);


-- TABLA CLIENTE CONTRATO
CREATE TABLE ClienteContrato (
    idClienteContrato INT IDENTITY(1,1) PRIMARY KEY,
    identificacion INT NOT NULL,
    idRol INT NOT NULL,
    idContrato INT NOT NULL
    -- Foreign keys
    CONSTRAINT FK_ClienteContrato_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion),
    CONSTRAINT FK_ClienteContrato_TipoRol FOREIGN KEY (idRol) REFERENCES TipoRol(idRol),
    CONSTRAINT FK_ClienteContrato_Contrato FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato)
)
GO

-- TABLA CONTRATO TERMINOS
CREATE TABLE ContratoTerminos (
    idContratoTerminos INT IDENTITY(1,1) PRIMARY KEY,
    idCondicion INT NOT NULL,
    idContrato INT NOT NULL
    -- Foreign keys
    CONSTRAINT FK_ContratoTerminos_TerminosCondiciones FOREIGN KEY (idCondicion) REFERENCES TerminosCondiciones(idCondicion),
    CONSTRAINT FK_ContratoTerminos_Contrato FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato)
);


-- FACTURA (Contrato, Agente)
CREATE TABLE Factura(
    idFactura INT IDENTITY(1,1) NOT NULL,
    montoPagado DECIMAL(18,2) NOT NULL,
    fechaEmision DATETIME NOT NULL DEFAULT GetDate(),
    fechaPago DATETIME NULL,
    estadoPago BIT NOT NULL DEFAULT 0,
	porcentajeIva DECIMAL(5,2) NULL,
    iva DECIMAL(18,2) NOT NULL,
    idContrato INT NOT NULL,
    idAgente INT NOT NULL,
    idPropiedad int NOT NULL,
    idTipoContrato INT NULL,
    montoComision DECIMAL(18,2) NOT NULL,
    porcentajeComision DECIMAL(5,2) NOT NULL,
    CONSTRAINT pk_FacturaIdFactura PRIMARY KEY (idFactura)
) ON Facturas;
GO

ALTER TABLE Factura
ADD CONSTRAINT Fk_FacturaIdContrato
FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato);

ALTER TABLE Factura
ADD CONSTRAINT Fk_FacturaIdAgente
FOREIGN KEY (idAgente) REFERENCES Agente(identificacion);

ALTER TABLE FACTURA
ADD CONSTRAINT Fk_FacturaIdPropiedad
FOREIGN KEY (idPropiedad) REFERENCES Propiedad(idPropiedad);

ALTER TABLE Factura
ADD CONSTRAINT Fk_FacturaIdTipoContrato
FOREIGN KEY (idTipoContrato) REFERENCES TipoContrato(idTipoContrato);
GO

-- CHECKS
ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_MontoPagado_Positivo CHECK (montoPagado >= 0);

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_Iva_Positivo CHECK (iva >= 0);

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_MontoComision_Positivo CHECK (montoComision >= 0);

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_FechaEmision_Valida
CHECK (fechaEmision <= GETDATE() AND fechaEmision >= '2000-01-01');

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_EstadoPago_Valido CHECK (estadoPago IN (0, 1));

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_IdContrato_Positivo CHECK (idContrato IS NOT NULL AND idContrato > 0);

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_IdAgente_Positivo CHECK ( idAgente > 0);
GO

-- FACTURA CLIENTE (Cliente, Factura)
CREATE TABLE FacturaCliente (
    idFacturaCliente INT IDENTITY(1,1) PRIMARY KEY,
    identificacion INT NOT NULL,
    idFactura INT NOT NULL,
    CONSTRAINT FK_FacturaCliente_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion),
    CONSTRAINT FK_FacturaCliente_Factura FOREIGN KEY (idFactura) REFERENCES Factura(idFactura)
);
GO

--    TABLA COMISION

create table Comision(
    idComision int identity(1,1), 
    idAgente int not null,
    idFactura int not null,
    idContrato int not null,
    fechaComision datetime not null default GetDate(),
    montoComision Decimal(18,2) not null,
    porcentajeComision Decimal(5,2) not null,
    estado bit not null default 1, -- 1 = activa, 0 = anulada
    mes as month(fechaComision) persisted,
    anio as year(fechaComision) persisted

)On Facturas
GO


ALTER TABLE Comision
ADD CONSTRAINT Fk_ComisionIdAgente
FOREIGN KEY (idAgente) REFERENCES Agente(identificacion);
GO

ALTER TABLE Comision
ADD CONSTRAINT Fk_ComisionIdFactura
FOREIGN KEY (idFactura) REFERENCES Factura(idFactura);
GO

ALTER TABLE Comision
ADD CONSTRAINT Fk_ComisionIdContrato
FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato);
GO

-- CHECKS

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_Monto_Positivo
CHECK (montoComision >= 0);

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_Porcentaje_Rango
CHECK (porcentajeComision >= 0 AND porcentajeComision <= 100);

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_Estado_Valido
CHECK (estado IN (0,1));

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_IdAgente_Pos CHECK (idAgente > 0);

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_IdContrato_Pos CHECK (idContrato > 0);

ALTER TABLE Comision
ADD CONSTRAINT ck_Comision_IdFactura_Pos CHECK (idFactura > 0);
GO