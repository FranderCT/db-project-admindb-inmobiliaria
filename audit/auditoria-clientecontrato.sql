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


CREATE OR ALTER TRIGGER tr_auditoria_cliente_contrato
ON ClienteContrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Obtener información del usuario desde SESSION_CONTEXT
    DECLARE 
        @correo NVARCHAR(150) = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100) = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100) = HOST_NAME();

    -- 2. Armar el campo usuario de auditoría
    DECLARE @usuario NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');

    -- 3. INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'INSERT', @usuario, @host
        FROM inserted;

    -- 4. UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'UPDATE', @usuario, @host
        FROM inserted;

    -- 5. DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'DELETE', @usuario, @host
        FROM deleted;
END;
GO

