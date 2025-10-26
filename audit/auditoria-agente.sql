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
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE TRIGGER tr_auditoria_agente
ON Agente
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener el usuario que realiza la acción desde SESSION_CONTEXT
    DECLARE @usuario NVARCHAR(100) = CAST(SESSION_CONTEXT(N'usuario_jwt') AS NVARCHAR(100));
    DECLARE @host NVARCHAR(100) = HOST_NAME();

    -- INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaAgente (idAgente, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, accion, usuario, host)
        SELECT identificacion, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, 'INSERT', @usuario, @host FROM inserted;

    -- UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaAgente (idAgente, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, accion, usuario, host)
        SELECT identificacion, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, 'UPDATE', @usuario, @host FROM inserted;

    -- DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaAgente (idAgente, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, accion, usuario, host)
        SELECT identificacion, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado, 'DELETE', @usuario, @host FROM deleted;
END;
GO
