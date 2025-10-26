CREATE TABLE AuditoriaClienteContrato (
    idAuditoriaClienteContrato INT IDENTITY PRIMARY KEY,
    idClienteContrato INT,
    identificacion INT,      -- Cliente
    idRol INT,               -- Rol del cliente (inquilino, comprador, etc.)
    idContrato INT,          -- Contrato vinculado
    accion NVARCHAR(10),     -- INSERT, UPDATE, DELETE
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO


CREATE TRIGGER tr_auditoria_cliente_contrato
ON ClienteContrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(100) = CAST(SESSION_CONTEXT(N'usuario_jwt') AS NVARCHAR(100));
    DECLARE @host NVARCHAR(100) = HOST_NAME();

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaClienteContrato (idClienteContrato, identificacion, idRol, idContrato, accion, usuario, host)
        SELECT idClienteContrato, identificacion, idRol, idContrato, 'INSERT', @usuario, @host FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaClienteContrato (idClienteContrato, identificacion, idRol, idContrato, accion, usuario, host)
        SELECT idClienteContrato, identificacion, idRol, idContrato, 'UPDATE', @usuario, @host FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaClienteContrato (idClienteContrato, identificacion, idRol, idContrato, accion, usuario, host)
        SELECT idClienteContrato, identificacion, idRol, idContrato, 'DELETE', @usuario, @host FROM deleted;
END;
GO
