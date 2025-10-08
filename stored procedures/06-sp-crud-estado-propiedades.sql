-- sp para insertar estados de propiedades
use AltosDelValle
GO
create or alter procedure sp_estadopropiedad_insertar
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

create or alter procedure sp_estadoPropiedad_LeerTodos
AS
BEGIN
    SET NOCOUNT ON;
    if NOT EXISTS (SELECT 1 FROM EstadoPropiedad)
        PRINT 'No hay estados de propiedades registrados.';
    ELSE
    SELECT idEstadoPropiedad, nombre FROM EstadoPropiedad;
END
GO

-- quiero elimninar todos los estados de propiedad del 1 al 8
