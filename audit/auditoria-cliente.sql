CREATE TABLE AuditoriaCliente (
    idAuditoriaCliente INT IDENTITY PRIMARY KEY,
    idCliente INT,
    nombre VARCHAR(30),
    apellido1 VARCHAR(30),
    apellido2 VARCHAR(30),
    telefono VARCHAR(30),
    estado BIT,
    accion NVARCHAR(10),
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE OR ALTER TRIGGER tr_auditoria_cliente
ON Cliente
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Obtener datos del contexto (token JWT)
    DECLARE 
        @correo NVARCHAR(150) = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100) = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100) = HOST_NAME();

    -- 2. Armar campo usuario para auditoría
    DECLARE @usuario NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');

    -- 3. INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaCliente (
            idCliente, nombre, apellido1, apellido2, telefono, estado,
            accion, usuario, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono, estado,
            'INSERT', @usuario, @host
        FROM inserted;

    -- 4. UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaCliente (
            idCliente, nombre, apellido1, apellido2, telefono, estado,
            accion, usuario, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono, estado,
            'UPDATE', @usuario, @host
        FROM inserted;

    -- 5. DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaCliente (
            idCliente, nombre, apellido1, apellido2, telefono, estado,
            accion, usuario, host
        )
        SELECT 
            identificacion, nombre, apellido1, apellido2, telefono, estado,
            'DELETE', @usuario, @host
        FROM deleted;
END;
GO
