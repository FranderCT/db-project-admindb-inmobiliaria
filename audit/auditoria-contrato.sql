CREATE TABLE AuditoriaContrato (
    idAuditoriaContrato INT IDENTITY PRIMARY KEY,
    idContrato INT,
    fechaInicio DATETIME,
    fechaFin DATETIME,
    fechaFirma DATETIME,
    fechaPago DATETIME,
    idTipoContrato INT,
    idPropiedad INT,
    idAgente INT,
    montoTotal MONEY,
    deposito MONEY,
    porcentajeComision DECIMAL(5,2),
    estado NVARCHAR(30),
    accion NVARCHAR(10),
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE OR ALTER TRIGGER tr_auditoria_contrato
ON Contrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Extrae el contexto actual del usuario JWT
    DECLARE 
        @correo NVARCHAR(150) = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100) = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100) = HOST_NAME();

    -- Combina el usuario con su rol (ejemplo: "carrillo2@gmail.com (Rol: agente)")
    DECLARE @usuario NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, accion, usuario, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, 'INSERT', @usuario, @host
        FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, accion, usuario, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, 'UPDATE', @usuario, @host
        FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaContrato (
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, accion, usuario, host
        )
        SELECT 
            idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente, montoTotal, deposito,
            porcentajeComision, estado, 'DELETE', @usuario, @host
        FROM deleted;
END;
GO

