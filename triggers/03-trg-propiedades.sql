-- TRIGGERS TABLA PROPIEDAD
use AltosDelValle;
GO
CREATE TRIGGER trg_GenerarCodigoPropiedad
ON Propiedad
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @nextNum INT;

    SELECT @nextNum = ISNULL(MAX(CAST(SUBSTRING(idPropiedad, 6, LEN(idPropiedad)) AS INT)), 0) + 1
    FROM Propiedad;

    INSERT INTO Propiedad (idPropiedad, ubicacion, precio, idEstado, idTipoInmueble, identificacion)
    SELECT 
        'PROP-' + RIGHT('0000' + CAST(@nextNum AS VARCHAR(4)), 4),
        ubicacion,
        precio,
        idEstado,
        idTipoInmueble,
        identificacion
    FROM inserted;
END;
GO
