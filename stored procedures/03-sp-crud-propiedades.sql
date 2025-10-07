-- SP_INSERT 
USE AltosDelValle
GO
create or alter procedure sp_insertPropiedad
	@_ubicacion		varchar(100),
	@_precio         money,
	@_idEstado       int,
	@_idTipoInmueble int,
	@_identificacion int
as
begin
begin try
    begin transaction;

      declare @existeEstado int;
      declare @existeTipo int;
      declare @existeCliente int;
      declare @nuevoIdPropiedad int;

      if @_ubicacion is null or LTRIM(RTRIM(@_ubicacion)) = ''
      begin
        print 'La ubicación es obligatoria.';
        rollback transaction; 
		return;
      end

      if @_precio is null or @_precio <= 0
      begin
        print 'El precio debe ser mayor a 0.';
        rollback transaction; 
		return;
      end

      select @existeEstado = idEstadoPropiedad
		  from EstadoPropiedad
		  where idEstadoPropiedad = @_idEstado;

      if @existeEstado is null
      begin
        print 'Ese estado no existe.';
        rollback transaction; 
		return;
      end

      select @existeTipo = idTipoInmueble
		  from TipoInmueble
		  where idTipoInmueble = @_idTipoInmueble;

      if @existeTipo is null
      begin
        print 'Ese tipo de inmueble no existe.';
        rollback transaction; 
		return;
      end

      select @existeCliente = identificacion
		  from Cliente
		  where identificacion = @_identificacion;

      if @existeCliente is null
      begin
        print 'No existe un cliente con esa identificación.';
        rollback transaction; 
		return;
      end

      insert into Propiedad
        (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
      values
        (@_ubicacion, @_precio, @_idEstado, @_idTipoInmueble, @_identificacion);

    commit transaction;

    print 'Propiedad registrada correctamente.';
    select @nuevoIdPropiedad as idPropiedad;
end try

  begin catch
    if XACT_STATE() <> 0 rollback transaction;
    print 'Error: ' + ERROR_MESSAGE();
  end catch
end 
go

-- SP_READ BY ID
USE AltosDelValle
GO
create or alter procedure sp_consultarPropiedad
  @_idPropiedad int
as
begin
	begin try
		if not exists (select 1 from Propiedad where idPropiedad = @_idPropiedad)
		begin
		  print 'No existe una propiedad asociada a ese ID';
		  return;
		end

		-- Si quieres devolver con joins descriptivos, descomenta el bloque JOIN
		select	p.*, 
				e.nombre as 'Estado', 
				t.nombre as 'Tipo de Inmueble'
		from Propiedad p
			JOIN EstadoPropiedad e on e.idEstadoPropiedad = p.idEstado
			JOIN TipoInmueble t on t.idTipoInmueble = p.idTipoInmueble
		where p.idPropiedad = @_idPropiedad;

	end try
	begin catch
		print 'Error: ' + ERROR_MESSAGE();
	end catch
end 
go

-- SP_UPDATE
USE AltosDelValle
GO
create or alter procedure sp_updatePropiedad
  @_idPropiedad      int,
  @_ubicacion        varchar(100),
  @_precio           money,
  @_idEstado         int,
  @_idTipoInmueble   int,
  @_identificacion   int
as
begin
  begin try
    begin transaction

      declare @existePropiedad int;
      declare @existeEstado int;
      declare @existeTipo int;
      declare @existeCliente int;

      select @existePropiedad = idPropiedad
		  from Propiedad
		  where idPropiedad = @_idPropiedad;

      if @existePropiedad is null
      begin
        print 'La propiedad no existe.';
        rollback transaction;
		return;
      end

      if @_ubicacion is null or LTRIM(RTRIM(@_ubicacion)) = ''
      begin
        print 'La ubicación es obligatoria.';
        rollback transaction; 
		return;
      end

      if @_precio is null or @_precio <= 0
      begin
        print 'El precio debe ser mayor a 0.';
        rollback transaction; 
		return;
      end

           select @existeEstado = idEstadoPropiedad
		  from EstadoPropiedad
		  where idEstadoPropiedad = @_idEstado;

      if @existeEstado is null
      begin
        print 'Ese estado no existe.';
        rollback transaction; 
		return;
      end

      select @existeTipo = idTipoInmueble
		  from TipoInmueble
		  where idTipoInmueble = @_idTipoInmueble;

      if @existeTipo is null
      begin
        print 'Ese tipo de inmueble no existe.';
        rollback transaction; 
		return;
      end

      select @existeCliente = identificacion
		  from Cliente
		  where identificacion = @_identificacion;

      if @existeCliente is null
      begin
        print 'No existe un cliente con esa identificación.';
        rollback transaction; 
		return;
      end

      -- Actualizar
      UPDATE Propiedad
      set ubicacion = @_ubicacion,
          precio = @_precio,
          idEstado = @_idEstado,
          idTipoInmueble = @_idTipoInmueble,
          identificacion = @_identificacion
      where idPropiedad = @_idPropiedad;

    commit transaction
		print 'Propiedad actualizada correctamente.';
	end try
	begin catch
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
		PRINT 'Error: ' + ERROR_MESSAGE();
	end catch
end
go

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