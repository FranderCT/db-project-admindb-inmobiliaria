-- CREACION DE TODAS LAS TABLAS

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
    comisionAcumulada DECIMAL(18, 2) NOT NULL DEFAULT 0,
    estado BIT NOT NULL DEFAULT 1
);
GO


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

CREATE TABLE Contrato(
	idContrato INT IDENTITY(1,1) NOT NULL,
	fechaInicio DATETIME NOT NULL, 
	fechaFin DATETIME NOT NULL, 
	fechaFirma DATETIME NOT NULL, 
	fechaPago DATETIME NOT NULL,
	idTipoContrato INT NOT NULL,
	idPropiedad INT NOT NULL, 
	idAgente INT NOT NULL, 
	idCondicion INT NOT NULL,
    CONSTRAINT pk_ContratoIdContrato PRIMARY KEY (idContrato)
) ON Contratos;
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

ALTER TABLE Contrato
ADD CONSTRAINT Fk_ContratoIdCondicion
FOREIGN KEY (idCondicion) REFERENCES TerminosCondiciones(idCondicion);

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

ALTER TABLE Contrato 
ADD CONSTRAINT CK_Contrato_IdCondicion_Pos CHECK (idCondicion IS NULL OR idCondicion > 0);
GO

-- CLIENTE CONTRATO (Cliente, TipoRol, Contrato)
CREATE TABLE ClienteContrato (
    idClienteContrato INT IDENTITY(1,1) PRIMARY KEY,
    identificacion INT NOT NULL,
    idRol INT NOT NULL,
    idContrato INT NOT NULL,
    CONSTRAINT FK_ClienteContrato_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion),
    CONSTRAINT FK_ClienteContrato_TipoRol FOREIGN KEY (idRol) REFERENCES TipoRol(idRol),
    CONSTRAINT FK_ClienteContrato_Contrato FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato)
);
GO

-- CONTRATO TERMINOS (Contrato, TerminosCondiciones)
CREATE TABLE ContratoTerminos (
    idContratoTerminos INT IDENTITY(1,1) PRIMARY KEY,
    idCondicion INT NOT NULL,
    idContrato INT NOT NULL,
    CONSTRAINT FK_ContratoTerminos_TerminosCondiciones FOREIGN KEY (idCondicion) REFERENCES TerminosCondiciones(idCondicion),
    CONSTRAINT FK_ContratoTerminos_Contrato FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato)
);
GO

-- FACTURA (Contrato, Agente)
CREATE TABLE Factura(
    idFactura INT IDENTITY(1,1) NOT NULL,
    montoPagado MONEY NOT NULL,
    fechaEmision DATETIME NOT NULL,
    estadoPago BIT NOT NULL,
    iva MONEY NOT NULL,
    idContrato INT NOT NULL,
    idAgente INT NOT NULL,
    montoComision MONEY NOT NULL,
    porcentajeComision MONEY NOT NULL,
    CONSTRAINT pk_FacturaIdFactura PRIMARY KEY (idFactura)
) ON Facturas;
GO

ALTER TABLE Factura
ADD CONSTRAINT Fk_FacturaIdContrato
FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato);

ALTER TABLE Factura
ADD CONSTRAINT Fk_FacturaIdAgente
FOREIGN KEY (idAgente) REFERENCES Agente(identificacion);

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
ADD CONSTRAINT ck_Factura_IdContrato_Positivo CHECK (idContrato IS NULL OR idContrato > 0);

ALTER TABLE Factura
ADD CONSTRAINT ck_Factura_IdAgente_Positivo CHECK (idAgente IS NULL OR idAgente > 0);
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

