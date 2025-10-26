CREATE TABLE AuditoriaFactura (
    idAuditoriaFactura INT IDENTITY PRIMARY KEY,
    idFactura INT,
    montoPagado MONEY,
    fechaEmision DATETIME,
    estadoPago BIT,
    iva MONEY,
    idContrato INT,
    idAgente INT,
    montoComision MONEY,
    porcentajeComision MONEY,
    accion NVARCHAR(10),
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE TRIGGER tr_auditoria_factura
ON Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(100) = CAST(SESSION_CONTEXT(N'usuario_jwt') AS NVARCHAR(100));
    DECLARE @host NVARCHAR(100) = HOST_NAME();

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFactura (idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, accion, usuario, host)
        SELECT idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, 'INSERT', @usuario, @host FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFactura (idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, accion, usuario, host)
        SELECT idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, 'UPDATE', @usuario, @host FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaFactura (idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, accion, usuario, host)
        SELECT idFactura, montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision, 'DELETE', @usuario, @host FROM deleted;
END;
GO
