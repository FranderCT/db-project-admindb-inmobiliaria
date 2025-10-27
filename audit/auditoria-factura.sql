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

CREATE OR ALTER TRIGGER tr_auditoria_factura
ON Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Obtener información del usuario desde SESSION_CONTEXT
    DECLARE 
        @correo NVARCHAR(150) = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100) = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100) = HOST_NAME();

    -- 2. Construir el campo usuario para auditoría
    DECLARE @usuario NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');

    -- 3. INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            accion, usuario, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            'INSERT', @usuario, @host
        FROM inserted;

    -- 4. UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            accion, usuario, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            'UPDATE', @usuario, @host
        FROM inserted;

    -- 5. DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            accion, usuario, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, estadoPago, iva,
            idContrato, idAgente, montoComision, porcentajeComision,
            'DELETE', @usuario, @host
        FROM deleted;
END;
GO
