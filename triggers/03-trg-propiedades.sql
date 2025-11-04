use AltosDelValle
GO

CREATE OR ALTER TRIGGER trg_GenerarCodigoPropiedad
ON dbo.Propiedad
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @anio INT = YEAR(GETDATE());
    DECLARE @prefijo INT = @anio * 10000; -- ejemplo: 2025 → 20250000
    DECLARE @nextNum INT;

    -- Obtener el último consecutivo del año actual
    SELECT 
        @nextNum = ISNULL(MAX(idPropiedad % 10000), 0) + 1
    FROM Propiedad
    WHERE idPropiedad / 10000 = @anio;

    -- Insertar nuevas filas con id generado
    -- Aseguramos valores por defecto para columnas NOT NULL para evitar errores de INSERT
    INSERT INTO Propiedad (idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion, imagenUrl, cantHabitaciones, cantBannios, areaM2, amueblado)
    SELECT 
        @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @nextNum - 1,
        ubicacion,
        precio,
        idEstado,
        idTipoInmueble,
        identificacion,
        imagenUrl,
        cantHabitaciones,
        cantBannios,
        areaM2,
        amueblado
    FROM inserted;
END;
GO