USE AltosDelValle;
GO

--  Tabla 
CREATE TABLE AuditoriaAgente (
    idAuditoriaAgente INT IDENTITY PRIMARY KEY,
    idAgente INT,
    nombre VARCHAR(30),
    apellido1 VARCHAR(30),
    apellido2 VARCHAR(30),
    telefono VARCHAR(30),
    comisionAcumulada DECIMAL(18,2),
    estado BIT,
    accion NVARCHAR(10),
    usuario NVARCHAR(250),   
    usuarioBD NVARCHAR(100),   
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO
--  Trigger 
CREATE OR ALTER TRIGGER tr_auditoria_agente
ON Agente
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    -- Valores del contexto del token (pasados desde backend con SESSION_CONTEXT)
    DECLARE 
        @correo NVARCHAR(150)     = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100)  = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100)       = HOST_NAME(),
        @usuarioBD NVARCHAR(100)  = ORIGINAL_LOGIN();
    -- Formatear usuario con datos del token
    DECLARE @usuarioToken NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');
    -- INSERT
    IF EXISTS (SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaAgente (
            idAgente, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, accion, usuario, usuarioBD, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, 'INSERT', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaAgente (
            idAgente, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, accion, usuario, usuarioBD, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, 'UPDATE', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END
    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaAgente (
            idAgente, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, accion, usuario, usuarioBD, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono,
            comisionAcumulada, estado, 'DELETE', @usuarioToken, @usuarioBD, @host
        FROM deleted;
    END
END;
GO
