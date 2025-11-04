USE AltosDelValle
GO

-- FACTURA (Contrato, Agente)
CREATE TABLE Factura(
    idFactura INT,
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
    idFactura INT,
    CONSTRAINT FK_FacturaCliente_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion),
    CONSTRAINT FK_FacturaCliente_Factura FOREIGN KEY (idFactura) REFERENCES Factura(idFactura)
);
GO

--    TABLA COMISION

create table Comision(
    idComision int identity(1,1), 
    idAgente int not null,
    idFactura int,
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