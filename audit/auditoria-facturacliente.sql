CREATE TABLE AuditoriaFacturaCliente (
    idAuditoriaFacturaCliente INT IDENTITY PRIMARY KEY,
    idFacturaCliente INT,
    identificacion INT,    -- Cliente
    idFactura INT,         -- Factura vinculada
    accion NVARCHAR(10),   -- INSERT, UPDATE, DELETE
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE TRIGGER tr_auditoria_factura_cliente
ON FacturaCliente
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(100) = CAST(SESSION_CONTEXT(N'usuario_jwt') AS NVARCHAR(100));
    DECLARE @host NVARCHAR(100) = HOST_NAME();

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFacturaCliente (idFacturaCliente, identificacion, idFactura, accion, usuario, host)
        SELECT idFacturaCliente, identificacion, idFactura, 'INSERT', @usuario, @host FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFacturaCliente (idFacturaCliente, identificacion, idFactura, accion, usuario, host)
        SELECT idFacturaCliente, identificacion, idFactura, 'UPDATE', @usuario, @host FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaFacturaCliente (idFacturaCliente, identificacion, idFactura, accion, usuario, host)
        SELECT idFacturaCliente, identificacion, idFactura, 'DELETE', @usuario, @host FROM deleted;
END;
GO
