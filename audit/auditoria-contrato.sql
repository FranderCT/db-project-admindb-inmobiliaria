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

CREATE TRIGGER tr_auditoria_contrato
ON Contrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(100) = CAST(SESSION_CONTEXT(N'usuario_jwt') AS NVARCHAR(100));
    DECLARE @host NVARCHAR(100) = HOST_NAME();

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaContrato (idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, accion, usuario, host)
        SELECT idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, 'INSERT', @usuario, @host FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaContrato (idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, accion, usuario, host)
        SELECT idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, 'UPDATE', @usuario, @host FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaContrato (idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, accion, usuario, host)
        SELECT idContrato, fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, estado, 'DELETE', @usuario, @host FROM deleted;
END;
GO
