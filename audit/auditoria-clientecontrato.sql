USE AltosDelValle;
GO
--  Tabla 
-- ========================================
CREATE TABLE AuditoriaClienteContrato (
    idAuditoriaClienteContrato INT IDENTITY PRIMARY KEY,
    idClienteContrato INT,
    identificacion INT,        
    idRol INT,                   
    idContrato INT,              
    accion NVARCHAR(10),       
    usuario NVARCHAR(250),       
    usuarioBD NVARCHAR(100),     
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

-- Trigger 
-- ========================================
CREATE OR ALTER TRIGGER tr_auditoria_cliente_contrato
ON ClienteContrato
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    --  Obtener datos del contexto (desde backend)
    DECLARE 
        @correo NVARCHAR(150)     = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100)  = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100)       = HOST_NAME(),
        @usuarioBD NVARCHAR(100)  = ORIGINAL_LOGIN();
    -- Formatear el nombre del usuario desde el token
    DECLARE @usuarioToken NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');
    --  INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'INSERT', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'UPDATE', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    --  DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaClienteContrato (
            idClienteContrato, identificacion, idRol, idContrato,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idClienteContrato, identificacion, idRol, idContrato,
            'DELETE', @usuarioToken, @usuarioBD, @host
        FROM deleted;
    END
END;
GO
