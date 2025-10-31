CREATE TABLE AuditoriaPropiedad (
    idAuditoriaPropiedad INT IDENTITY PRIMARY KEY,
    idPropiedad int,
    ubicacion VARCHAR(100),
    precio MONEY,
    idEstado INT,
    idTipoInmueble INT,
    identificacion INT,
    accion NVARCHAR(10),
    usuario NVARCHAR(100),
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

CREATE OR ALTER TRIGGER tr_auditoria_propiedad
ON Propiedad
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Obtener datos del contexto de sesión (JWT)
    DECLARE 
        @correo NVARCHAR(150) = CAST(SESSION_CONTEXT(N'correo') AS NVARCHAR(150)),
        @nombreRol NVARCHAR(100) = CAST(SESSION_CONTEXT(N'nombreRol') AS NVARCHAR(100)),
        @host NVARCHAR(100) = HOST_NAME();

    -- 2. Construir el nombre del usuario para la auditoría
    DECLARE @usuario NVARCHAR(250) = 
        CONCAT(ISNULL(@correo, 'Desconocido'), ' (Rol: ', ISNULL(@nombreRol, 'Sin rol'), ')');

    -- 3. INSERT
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            accion, usuario, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            'INSERT', @usuario, @host
        FROM inserted;

    -- 4. UPDATE
    IF EXISTS (SELECT * FROM inserted)
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            accion, usuario, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            'UPDATE', @usuario, @host
        FROM inserted;

    -- 5. DELETE
    IF EXISTS (SELECT * FROM deleted)
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            accion, usuario, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            'DELETE', @usuario, @host
        FROM deleted;
END;
GO

