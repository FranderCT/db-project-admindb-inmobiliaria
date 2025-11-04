-- sp para insertar estados de propiedades
use AltosDelValle
GO
create or alter procedure sp_insertEstadoPropiedad
    @nombre VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM EstadoPropiedad WHERE nombre = @nombre)
        THROW 50000, 'El estado de propiedad ya existe.', 1;

    ELSE
    INSERT INTO EstadoPropiedad (nombre)
    VALUES (@nombre);

    SELECT nombre FROM EstadoPropiedad WHERE nombre = @nombre;
END
GO

-- sp para leer todos los estados de propiedades
use AltosDelValle
GO
create or alter procedure sp_readEstadoPropiedad
AS
BEGIN
    SET NOCOUNT ON;
    if NOT EXISTS (SELECT 1 FROM EstadoPropiedad)
        PRINT 'No hay estados de propiedades registrados.';
    ELSE
    SELECT idEstadoPropiedad, nombre FROM EstadoPropiedad;
END
GO



EXEC dbo.sp_insertEstadoPropiedad @nombre = 'Disponible';
EXEC dbo.sp_insertEstadoPropiedad @nombre = 'Reservada';
EXEC dbo.sp_insertEstadoPropiedad @nombre = 'En mantenimiento';
EXEC dbo.sp_insertEstadoPropiedad @nombre = 'Vendida';

select * from EstadoPropiedad;
