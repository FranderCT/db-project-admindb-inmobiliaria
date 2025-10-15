USE AltosDelValle
GO

--			TABLA FACTURA
create table Factura(
    idFactura int identity (1,1) not null,
    montoPagado money not null,
    fechaEmision datetime not null,
    estadoPago bit not null,
    iva money not null,
    idContrato int not null,
    idAgente int not null,
    montoComision money not null,
    porcentajeComision money not null

)On Facturas
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


