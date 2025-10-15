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
	@identificacion int
as
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

  -- insertamos la propiedad
  insert into Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
  values (@ubicacion, @precio, @idEstado, @idTipoInmueble, @identificacion);
  print 'Propiedad insertada correctamente.';
  select * from Propiedad where idPropiedad = SCOPE_IDENTITY();

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
        print 'La ubicaci�n es obligatoria.';
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
        print 'No existe un cliente con esa identificaci�n.';
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
go

-- sp para leer todas las propiedades paginadas y ordenadas
USE AltosDelValle
GO

CREATE OR ALTER PROCEDURE dbo.sp_propiedad_paginar_json
  @page     INT = 1,
  @limit    INT = 10,
  @sortCol  SYSNAME = 'idPropiedad',     -- columnas permitidas abajo
  @sortDir  VARCHAR(4) = 'ASC',          -- ASC | DESC
  @q        NVARCHAR(100) = NULL         -- búsqueda opcional
AS
BEGIN
  SET NOCOUNT ON;

  -- Sanitización
  IF @page  < 1 SET @page  = 1;
  IF @limit < 1 SET @limit = 10;
  IF @sortDir NOT IN ('ASC','DESC') SET @sortDir = 'ASC';

  -- Lista blanca (mapeada a columnas de Propiedad)
  IF @sortCol NOT IN ('idPropiedad','ubicacion','precio','idEstado','idTipoInmueble','identificacion')
    SET @sortCol = 'idPropiedad';

  DECLARE @offset INT = (@page - 1) * @limit;

  -- WHERE dinámico
  DECLARE @where NVARCHAR(MAX) = N'';
  DECLARE @hasQ BIT = 0;
  DECLARE @like NVARCHAR(200);

  IF @q IS NOT NULL AND LTRIM(RTRIM(@q)) <> N''
  BEGIN
    SET @hasQ = 1;
    SET @like = N'%' + @q + N'%';
    SET @where = N' WHERE (
        p.ubicacion LIKE @like
        OR CAST(p.precio AS NVARCHAR(50)) LIKE @like
        OR CAST(p.idEstado AS NVARCHAR(10)) LIKE @like
        OR CAST(p.idTipoInmueble AS NVARCHAR(10)) LIKE @like
        OR CAST(p.identificacion AS NVARCHAR(20)) LIKE @like
      )';
  END

  -- Temp table para mantener el orden de la página
  IF OBJECT_ID('tempdb..#page') IS NOT NULL DROP TABLE #page;
  CREATE TABLE #page (
    rn INT NOT NULL,
    idPropiedad INT NOT NULL PRIMARY KEY
  );

  DECLARE @total INT = 0;

  -- Dinámico: calcular total + volcar IDs paginados con un row number estable
  DECLARE @sql NVARCHAR(MAX) =
  N'
    SELECT @total_out = COUNT(*) 
    FROM dbo.Propiedad p
    /**WHERE**/;

    ;WITH S AS (
      SELECT p.idPropiedad,
             ROW_NUMBER() OVER (ORDER BY ' + QUOTENAME(@sortCol) + N' ' + @sortDir + N') AS rn
      FROM dbo.Propiedad p
      /**WHERE**/
    )
    INSERT INTO #page(rn, idPropiedad)
    SELECT rn, idPropiedad
    FROM S
    WHERE rn > @o AND rn <= (@o + @l);
  ';

  SET @sql = REPLACE(@sql, N'/**WHERE**/', @where);

  IF @hasQ = 1
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @like NVARCHAR(200), @total_out INT OUTPUT',
      @o=@offset, @l=@limit, @like=@like, @total_out=@total OUTPUT;
  ELSE
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @total_out INT OUTPUT',
      @o=@offset, @l=@limit, @total_out=@total OUTPUT;

  -- Devolver UN solo JSON con data (anidada) y meta
  SELECT
    JSON_QUERY((
      SELECT
        p.idPropiedad,
        p.ubicacion,
        p.precio,
        -- EstadoPropiedad
        e.idEstadoPropiedad AS [estadoPropiedad.idEstadoPropiedad],
        e.nombre            AS [estadoPropiedad.nombre],
        -- TipoInmueble
        ti.idTipoInmueble   AS [tipoInmueble.idTipoInmueble],
        ti.nombre           AS [tipoInmueble.nombre],
        -- Cliente
        c.identificacion    AS [cliente.identificacion],
        c.nombre            AS [cliente.nombre],
        c.apellido1         AS [cliente.apellido1],
        c.apellido2         AS [cliente.apellido2],
        c.telefono          AS [cliente.telefono],
        c.estado            AS [cliente.estado]
      FROM #page pg
      JOIN dbo.Propiedad       p  ON p.idPropiedad = pg.idPropiedad
      JOIN dbo.EstadoPropiedad e  ON p.idEstado = e.idEstadoPropiedad
      JOIN dbo.TipoInmueble    ti ON p.idTipoInmueble = ti.idTipoInmueble
      JOIN dbo.Cliente         c  ON p.identificacion = c.identificacion
      ORDER BY pg.rn
      FOR JSON PATH
    )) AS data,
      JSON_QUERY((
      SELECT
        @total                                             AS total,
        @page                                              AS page,
        @limit                                             AS limit,
        CASE WHEN @limit = 0 THEN 0
             ELSE CEILING(@total * 1.0 / @limit) END      AS pageCount,
        CASE WHEN (@page * @limit) < @total THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS hasNextPage,
        CASE WHEN @page > 1 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END                 AS hasPrevPage
      FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )) AS meta
  FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
END
GO



-- sp para leer todas las propiedades
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_propiedad_leerTodas
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 
    -- Propiedad
    p.idPropiedad,
    p.ubicacion,
    p.precio,

    -- EstadoPropiedad (relación)
    e.idEstadoPropiedad     AS [estadoPropiedad.idEstadoPropiedad],
    e.nombre                AS [estadoPropiedad.nombre],

    -- TipoInmueble (relación)
    ti.idTipoInmueble       AS [tipoInmueble.idTipoInmueble],
    ti.nombre               AS [tipoInmueble.nombre],

    -- Cliente (relación)
    c.identificacion        AS [cliente.identificacion],
    c.nombre                AS [cliente.nombre],
    c.apellido1             AS [cliente.apellido1],
    c.apellido2             AS [cliente.apellido2],
    c.telefono              AS [cliente.telefono],
    c.estado                AS [cliente.estado]

  FROM dbo.Propiedad AS p
  INNER JOIN dbo.EstadoPropiedad AS e
    ON p.idEstado = e.idEstadoPropiedad
  INNER JOIN dbo.TipoInmueble AS ti
    ON p.idTipoInmueble = ti.idTipoInmueble
  INNER JOIN dbo.Cliente AS c
    ON p.identificacion = c.identificacion
  FOR JSON PATH;
END
GO

-- final

