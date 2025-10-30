USE AltosDelValle;
GO
CREATE TRIGGER trg_GenerarCodigoPropiedad
ON Propiedad
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener la fecha actual en formato YYYYMM
    DECLARE @fechaActual VARCHAR(6) = FORMAT(GETDATE(), 'yyyyMM');

    -- Obtener el último número consecutivo generado en el mes actual
    DECLARE @ultimoConsecutivo INT = ISNULL((
        SELECT MAX(CAST(SUBSTRING(CAST(idPropiedad AS VARCHAR(20)), 7, 4) AS INT)) 
        FROM Propiedad
        WHERE SUBSTRING(CAST(idPropiedad AS VARCHAR(20)), 1, 6) = @fechaActual
    ), 0);

    -- Generar el nuevo número de propiedad basado en el consecutivo
    DECLARE @nuevoCodigo INT = CAST(@fechaActual AS INT) * 10000 + (@ultimoConsecutivo + 1);

    -- Insertar la propiedad con el nuevo idPropiedad generado
    INSERT INTO Propiedad (idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion)
    SELECT 
        @nuevoCodigo,  -- Nuevo idPropiedad generado
        ubicacion,
        precio,
        idEstado,
        idTipoInmueble,
        identificacion
    FROM inserted;
END;
GO
