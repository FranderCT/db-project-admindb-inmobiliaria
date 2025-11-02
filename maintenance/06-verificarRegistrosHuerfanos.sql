USE AltosDelValle
GO

SELECT * FROM Propiedad WHERE idEstado NOT IN (SELECT idEstadoPropiedad FROM EstadoPropiedad);
GO