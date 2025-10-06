--			TABLA FACTURA
USE AltosDelValle
GO


--			TABLA FACTURACLIENTE
CREATE TABLE FacturaCliente (
    idFacturaCliente INT IDENTITY(1,1) PRIMARY KEY,
    identificacion INT NOT NULL,
    idFactura INT NOT NULL
    -- Foreign keys
    CONSTRAINT FK_FacturaCliente_Cliente FOREIGN KEY (identificacion) REFERENCES Cliente(identificacion),
    CONSTRAINT FK_FacturaCliente_Factura FOREIGN KEY (idFactura) REFERENCES Factura(idFactura)
)
GO