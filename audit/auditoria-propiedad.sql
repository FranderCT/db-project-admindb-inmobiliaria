USE AltosDelValle;
GO


--  Tabla 
-- ========================================
CREATE TABLE AuditoriaPropiedad (
    idAuditoriaPropiedad INT IDENTITY PRIMARY KEY,
    idPropiedad INT,
    ubicacion VARCHAR(100),
    precio MONEY,
    idEstado INT,
    idTipoInmueble INT,
    identificacion INT,
    imagenUrl NVARCHAR(500),
    cantHabitaciones INT,
    cantBannios INT,
    areaM2 FLOAT,
    amueblado BIT,
    accion NVARCHAR(10),           
    usuario NVARCHAR(250),        
    usuarioBD NVARCHAR(100),      
    fecha DATETIME DEFAULT GETDATE(),
    host NVARCHAR(100)
);
GO

--  Trigger 
-- ========================================
CREATE OR ALTER TRIGGER tr_auditoria_propiedad
ON Propiedad
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener datos del contexto
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
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            'INSERT', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END

    -- UPDATE
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            'UPDATE', @usuarioToken, @usuarioBD, @host
        FROM inserted;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO AuditoriaPropiedad (
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            accion, usuario, usuarioBD, host
        )
        SELECT 
            idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion,
            imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado,
            'DELETE', @usuarioToken, @usuarioBD, @host
        FROM deleted;
    END
END;
GO

