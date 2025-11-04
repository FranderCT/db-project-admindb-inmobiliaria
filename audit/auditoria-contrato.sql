USE AltosDelValle;
GO

-- Tabla
-- ========================================
CREATE TABLE AuditoriaContrato (
    idAuditoriaContrato INT IDENTITY PRIMARY KEY,
    idContrato INT,
    fechaInicio DATETIME NULL,
    fechaFin DATETIME NULL,
    fechaFirma DATETIME NULL,
    fechaPago DATETIME NULL,
    idTipoContrato INT,
    idPropiedad INT,
    idAgente INT,
    montoTotal MONEY,
    deposito MONEY,
    porcentajeComision DECIMAL(5,2),
    cantidadPagos INT,
    estado NVARCHAR(30),
    accion NVARCHAR(10),           
    usuario NVARCHAR(250),         
    usuarioBD NVARCHAR(100),       
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO


-- Trigger
-- ========================================
CREATE OR ALTER TRIGGER tr_auditoria_contrato
ON Contrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Obtener datos del contexto del usuario
    DECLARE 
        @correo NVARCHAR(150)     = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100)  = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100)       = HOST_NAME(),
        @usuarioBD NVARCHAR(100)  = ORIGINAL_LOGIN();
    DECLARE @usuarioToken NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');
    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado, 
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado,
            'INSERT', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado, 
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado,
            'UPDATE', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado, 
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, cantidadPagos, estado,
            'DELETE', @usuarioToken, @usuarioBD, @host
        FROM deleted;
    END
END;
GO
