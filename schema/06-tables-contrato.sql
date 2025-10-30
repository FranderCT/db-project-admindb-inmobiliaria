USE AltosDelValle
GO

--			TABLA CONTRATO
create table Contrato(
	idContrato int identity (1,1)PRIMARY KEY not null,
	fechaInicio datetime not null, 
	fechaFin datetime not null, 
	fechaFirma datetime not null, 
	fechaPago datetime null,
	idTipoContrato int not null,
	idPropiedad VARCHAR(20) null, 
	idAgente int not null,
	montoTotal MONEY NULL,
    deposito MONEY NULL,
    porcentajeComision DECIMAL(5,2) NULL,
	cantidadPagos INT NULL, 
    estado NVARCHAR(30) DEFAULT 'Pendiente'
)on Contratos
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
