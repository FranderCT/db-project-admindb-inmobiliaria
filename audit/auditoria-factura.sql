USE AltosDelValle;
GO
--  Tabla 
-- ========================================
CREATE TABLE AuditoriaFactura (
    idAuditoriaFactura INT IDENTITY PRIMARY KEY,
    idFactura INT,
    montoPagado DECIMAL(18,2),
    fechaEmision DATETIME,
    fechaPago DATETIME,
    estadoPago BIT,
    porcentajeIva DECIMAL(5,2),
    iva DECIMAL(18,2),
    idContrato INT,
    idAgente INT,
    idPropiedad INT,
    idTipoContrato INT,
    montoComision DECIMAL(18,2),
    porcentajeComision DECIMAL(5,2),
    accion NVARCHAR(10),         
    usuario NVARCHAR(250),       
    usuarioBD NVARCHAR(100),     
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

--  Trigger 
-- ========================================
CREATE OR ALTER TRIGGER tr_auditoria_factura
ON Factura
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Obtener información del usuario desde SESSION_CONTEXT
    DECLARE 
        @correo NVARCHAR(150)     = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100)  = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100)       = HOST_NAME(),
        @usuarioBD NVARCHAR(100)  = ORIGINAL_LOGIN();
    --  Formatear usuario con su rol
    DECLARE @usuarioToken NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');
    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            'INSERT', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            'UPDATE', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    --  DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaFactura (
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
            porcentajeIva, iva, idContrato, idAgente, idPropiedad,
            idTipoContrato, montoComision, porcentajeComision,
            'DELETE', @usuarioToken, @usuarioBD, @host
        FROM deleted;
    END
END;
GO
