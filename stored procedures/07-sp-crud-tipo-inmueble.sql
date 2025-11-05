-- sp para insertar tipos de inmuebles
use AltosDelValle
GO
create or alter procedure sp_tipoInmuebleInsertar
    @nombre VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM TipoInmueble WHERE nombre = @nombre)
        THROW 50000, 'El tipo de inmueble ya existe.', 1;

    ELSE
    INSERT INTO TipoInmueble (nombre)
    VALUES (@nombre);
    SELECT nombre FROM TipoInmueble WHERE nombre = @nombre;
END
GO
-- sp para leer todos los tipos de inmuebles
create or alter procedure sp_tipoInmuebleLeerTodos
AS
BEGIN
    SET NOCOUNT ON;
    if NOT EXISTS (SELECT 1 FROM TipoInmueble)
        PRINT 'No hay tipos de inmuebles registrados.';
    ELSE
    SELECT idTipoInmueble, nombre FROM TipoInmueble;
END
GO


EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Apartamento';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Casa';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Condominio';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Centro comercial';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Local comercial';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Oficina';
EXEC dbo.sp_tipoInmuebleInsertar @nombre = 'Almacén';
GO
