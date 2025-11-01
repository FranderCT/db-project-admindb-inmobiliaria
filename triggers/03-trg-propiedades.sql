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
    INSERT INTO Propiedad (idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion)
    SELECT 
        @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @nextNum - 1,
        ubicacion,
        precio,
        idEstado,
        idTipoInmueble,
        identificacion
    FROM inserted;
END;
GO