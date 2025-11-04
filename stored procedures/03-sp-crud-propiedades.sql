use AltosDelValle
go


-- SP_INSERT 
use AltosDelValle
go
create or alter procedure sp_insertPropiedad
	@ubicacion		varchar(100),
	@precio         money,
	@idEstado       int,
	@idTipoInmueble int,
	@identificacion int,
	@imagenUrl NVARCHAR(500)=NULL,
	@cantHabitaciones int,
  @cantBannios int,
  @areaM2 FLOAT,
  @amueblado bit
AS
begin
  set nocount on;

  -- validar que idTipoInmueble exista
  declare @existeTipo int;
  select @existeTipo = idTipoInmueble
  from TipoInmueble
  where idTipoInmueble = @idTipoInmueble;

  if @existeTipo is null
  begin
    print 'Ese tipo de inmueble no existe.';
    return;
  end

  -- validar que idEstado exista
  declare @existeEstado int;
  select @existeEstado = idEstadoPropiedad
  from EstadoPropiedad
  where idEstadoPropiedad = @idEstado;

  if @existeEstado is null
  begin
    print 'Ese estado no existe.';
    return;
  end
  -- validar que identificacion exista
  declare @existeCliente int;
  select @existeCliente = identificacion
  from Cliente
  where identificacion = @identificacion;

  if @existeCliente is null
  begin
    print 'No existe un cliente con esa identificacion.';
    return;
  end

  SELECT 
    @ubicacion AS ubicacion,
    @precio AS precio,
    @idEstado AS idEstado,
    @idTipoInmueble AS idTipoInmueble,
    @identificacion AS identificacion,
    @imagenUrl AS imagenUrl,
    @cantBannios AS cantBannios,
    @areaM2 AS areaM2,
    @amueblado AS amueblado,
    @cantHabitaciones AS cantHabitaciones;

  -- insertamos la propiedad
  insert into Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion, imagenUrl, cantBannios, areaM2, amueblado, cantHabitaciones)
  values (@ubicacion, @precio, @idEstado, @idTipoInmueble, @identificacion, @imagenUrl, @cantBannios, @areaM2, @amueblado, @cantHabitaciones);
  print 'Propiedad insertada correctamente.';
  select * from Propiedad where idPropiedad = SCOPE_IDENTITY();

end
go

-- SP_UPDATE

CREATE OR ALTER PROCEDURE sp_updatePropiedad
  @_idPropiedad      INT,
  @_ubicacion        VARCHAR(100) = NULL,
  @_precio           MONEY = NULL,
  @_idEstado         INT = NULL,
  @_idTipoInmueble   INT = NULL,
  @_identificacion   INT = NULL
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;

    -- Verifica si la propiedad existe
    IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE idPropiedad = @_idPropiedad)
    BEGIN
      PRINT ' La propiedad no existe.';
      ROLLBACK TRANSACTION;
      RETURN;
    END

    -- Validaciones de parámetros solo si son proporcionados
    IF @_precio IS NOT NULL AND @_precio <= 0
    BEGIN
      PRINT ' El precio debe ser mayor a 0.';
      ROLLBACK TRANSACTION;
      RETURN;
    END

    IF @_idEstado IS NOT NULL AND NOT EXISTS (SELECT 1 FROM EstadoPropiedad WHERE idEstadoPropiedad = @_idEstado)
    BEGIN
      PRINT ' Ese estado no existe.';
      ROLLBACK TRANSACTION;
      RETURN;
    END

    IF @_idTipoInmueble IS NOT NULL AND NOT EXISTS (SELECT 1 FROM TipoInmueble WHERE idTipoInmueble = @_idTipoInmueble)
    BEGIN
      PRINT ' Ese tipo de inmueble no existe.';
      ROLLBACK TRANSACTION;
      RETURN;
    END

    IF @_identificacion IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Cliente WHERE identificacion = @_identificacion)
    BEGIN
      PRINT ' No existe un cliente con esa identificación.';
      ROLLBACK TRANSACTION;
      RETURN;
    END

    -- Actualiza solo los campos enviados, manteniendo los valores actuales si no se envían
    UPDATE Propiedad
    SET 
        ubicacion = CASE WHEN @_ubicacion IS NOT NULL THEN @_ubicacion ELSE ubicacion END,
        precio = CASE WHEN @_precio IS NOT NULL THEN @_precio ELSE precio END,
        idEstado = CASE WHEN @_idEstado IS NOT NULL THEN @_idEstado ELSE idEstado END,
        idTipoInmueble = CASE WHEN @_idTipoInmueble IS NOT NULL THEN @_idTipoInmueble ELSE idTipoInmueble END,
        identificacion = CASE WHEN @_identificacion IS NOT NULL THEN @_identificacion ELSE identificacion END
    WHERE idPropiedad = @_idPropiedad;

    COMMIT TRANSACTION;
    PRINT 'Propiedad actualizada correctamente.';
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
END
GO


-- SP_UPDATEESTADO
USE AltosDelValle
GO
create or alter procedure sp_updateEstadoPropiedad
  @_idPropiedad   int,
  @_idEstadoNuevo int
as
begin
	begin try
		begin transaction

		  declare @existePropiedad int;
		  declare @existeEstadoNuevo int;

		  select @existePropiedad = idPropiedad
		  from dbo.Propiedad
		  where idPropiedad = @_idPropiedad;

		  if @existePropiedad is null
		  begin
			print 'La propiedad no existe.';
			rollback transaction;
			return;
		  end

		  select @existeEstadoNuevo = idEstadoPropiedad
			  from dbo.EstadoPropiedad
			  where idEstadoPropiedad = @_idEstadoNuevo;

		  IF @existeEstadoNuevo is null
		  begin
			print 'El estado indicado no existe.';
			rollback transaction;
			return;
		  end

		  if EXISTS (
			select 1
			from Propiedad
				where idPropiedad = @_idPropiedad
				  and idEstado = @_idEstadoNuevo
		  )
		  begin
			print 'La propiedad ya tiene ese estado.';
			rollback transaction;
			return;
		  end

		  update Propiedad
		  set idEstado = @_idEstadoNuevo
		  where idPropiedad = @_idPropiedad;

		commit transaction

		print 'Estado de la propiedad actualizado correctamente.';
	end try
  begin catch
    if XACT_STATE() <> 0 rollback transaction;
    print 'Error: ' + ERROR_MESSAGE();
  end catch
end 
go

-- final


