-- SP_INSERT 
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Cliente_Insertar
  @identificacion INT,
  @nombre         VARCHAR(30),
  @apellido1      VARCHAR(30),
  @apellido2      VARCHAR(30) = NULL,
  @telefono       VARCHAR(30)
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE identificacion = @identificacion)
      THROW 50010, 'La identificación ya está registrada.', 1;
      
    IF @identificacion IS NULL OR @identificacion <= 0
      THROW 50011, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
      THROW 50012, 'El nombre es obligatorio.', 1;

    IF @apellido1 IS NULL OR LTRIM(RTRIM(@apellido1)) = ''
      THROW 50013, 'El primer apellido es obligatorio.', 1;

    IF @telefono IS NULL OR LTRIM(RTRIM(@telefono)) = ''
      THROW 50014, 'El teléfono es obligatorio.', 1;

    INSERT INTO dbo.Cliente (identificacion, nombre, apellido1, apellido2, telefono)
    VALUES (@identificacion, @nombre, @apellido1, @apellido2, @telefono);

    SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
    FROM dbo.Cliente
    WHERE identificacion = @identificacion;
  END TRY
  BEGIN CATCH
    DECLARE @num INT = ERROR_NUMBER(),
            @msg NVARCHAR(4000) = ERROR_MESSAGE();

    -- Si es un error de nuestros códigos 50010..50099, relanzamos igual.
    IF @num BETWEEN 50010 AND 50099
      THROW @num, @msg, 1;

    -- Si es otro error (FK, CHECK, etc.), lo envolvemos en un mensaje genérico
    DECLARE @fullMsg NVARCHAR(4000) = N'Error al insertar cliente: ' + @msg;
    THROW 50050, @fullMsg, 1;
  END CATCH
END
GO


 -- SP_READ con paginación, ordenamiento y filtros
USE AltosDelValle;
GO
CREATE OR ALTER PROCEDURE dbo.sp_cliente_paginar_orden
  @page     INT = 1,
  @limit    INT = 10,
  @sortCol  SYSNAME = 'identificacion',     -- columna permitida
  @sortDir  VARCHAR(4) = 'ASC',             -- 'ASC' | 'DESC'
  @q        NVARCHAR(100) = NULL,           -- término de búsqueda (opcional)
  @estado   BIT = NULL                      -- filtro por estado (opcional)
AS
BEGIN
  SET NOCOUNT ON;

  -- Sanitización básica
  IF @page  < 1 SET @page  = 1;
  IF @limit < 1 SET @limit = 10;
  IF @sortDir NOT IN ('ASC','DESC') SET @sortDir = 'ASC';

  -- Lista blanca de columnas permitidas para ORDER BY
  IF @sortCol NOT IN ('identificacion','nombre','apellido1','telefono','estado')
    SET @sortCol = 'identificacion';

  DECLARE @offset INT = (@page - 1) * @limit;

  -- Base SQL dinámica
  DECLARE @sql NVARCHAR(MAX) =
    N'SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
      FROM dbo.Cliente
      /**WHERE**/
      ORDER BY ' + QUOTENAME(@sortCol) + N' ' + @sortDir + N'
      OFFSET @o ROWS FETCH NEXT @l ROWS ONLY;

      SELECT COUNT(*) AS total,
             @p AS page,
             @l AS limit,
             CEILING(COUNT(*) * 1.0 / @l) AS pageCount,
             CASE WHEN (@p * @l) < COUNT(*) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS hasNextPage,
             CASE WHEN @p > 1 THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS hasPrevPage
      FROM dbo.Cliente
      /**WHERE**/;';

  DECLARE @where NVARCHAR(MAX) = N'';
  DECLARE @hasCondition BIT = 0;
  DECLARE @like NVARCHAR(200);

  -- Filtro por búsqueda
  IF @q IS NOT NULL AND LTRIM(RTRIM(@q)) <> N''
  BEGIN
    SET @hasCondition = 1;
    SET @like = N'%' + @q + N'%';

    SET @where = @where + N' WHERE (
        nombre LIKE @like
        OR apellido1 LIKE @like
        OR ISNULL(apellido2, '''') LIKE @like
        OR telefono LIKE @like
        OR CAST(identificacion AS NVARCHAR(20)) LIKE @like
        OR (nombre + N'' '' + apellido1 + ISNULL(N'' '' + apellido2, N'''')) LIKE @like
      )';
  END

  -- Filtro por estado
  IF @estado IS NOT NULL
  BEGIN
    IF @hasCondition = 1
      SET @where = @where + N' AND estado = @estado';
    ELSE
    BEGIN
      SET @hasCondition = 1;
      SET @where = N' WHERE estado = @estado';
    END
  END

  -- Inserta el WHERE dinámico en ambas partes del SQL
  SET @sql = REPLACE(@sql, N'/**WHERE**/', @where);

  -- Ejecuta SQL dinámica con los parámetros necesarios
  IF @q IS NOT NULL AND LTRIM(RTRIM(@q)) <> N'' AND @estado IS NOT NULL
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @p INT, @like NVARCHAR(200), @estado BIT',
      @o=@offset, @l=@limit, @p=@page, @like=@like, @estado=@estado;

  ELSE IF @q IS NOT NULL AND LTRIM(RTRIM(@q)) <> N''
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @p INT, @like NVARCHAR(200)',
      @o=@offset, @l=@limit, @p=@page, @like=@like;

  ELSE IF @estado IS NOT NULL
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @p INT, @estado BIT',
      @o=@offset, @l=@limit, @p=@page, @estado=@estado;

  ELSE
    EXEC sp_executesql
      @sql,
      N'@o INT, @l INT, @p INT',
      @o=@offset, @l=@limit, @p=@page;
END
GO



-- leer cliente por identificacion
CREATE OR ALTER PROCEDURE dbo.sp_cliente_porIdentificacion
    @identificacion INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @identificacion IS NULL OR @identificacion <= 0
        THROW 50000, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE identificacion = @identificacion)
        THROW 50000, 'Cliente no encontrado.', 1;

    SELECT identificacion,
           nombre,
           apellido1,
           apellido2,
           telefono,
           estado
    FROM dbo.Cliente
    WHERE identificacion = @identificacion;
END
GO

-- este sp da todos los datos de los clientes sin paginar

-- SP_UPDATE
CREATE OR ALTER PROCEDURE sp_cliente_actualizar
    @identificacion INT,
    @nombre         VARCHAR(30) = NULL,
    @apellido1      VARCHAR(30) = NULL,
    @apellido2      VARCHAR(30) = NULL,
    @telefono       VARCHAR(30) = NULL,
    @estado         BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    IF @identificacion IS NULL OR @identificacion <= 0
        THROW 50000, 'La identificación es obligatoria y debe ser > 0.', 1;
    -- Verificar que el cliente exista
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE identificacion = @identificacion)
        THROW 50000, 'Cliente no encontrado.', 1;
    -- Actualizar solo los campos que no son NULL
    UPDATE dbo.Cliente
    SET
        nombre = COALESCE(@nombre, nombre),
        apellido1 = COALESCE(@apellido1, apellido1),
        apellido2 = COALESCE(@apellido2, apellido2),
        telefono = COALESCE(@telefono, telefono),
        estado = COALESCE(@estado, estado)
    WHERE identificacion = @identificacion;
    
    SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
    FROM dbo.Cliente
    WHERE identificacion = @identificacion;

END
GO

-- SP_DELETE
-- este sp solo desactiva el cliente (estado = 0)
CREATE OR ALTER PROCEDURE sp_cliente_desactivar
    @identificacion INT
AS
BEGIN
    SET NOCOUNT ON;

    IF @identificacion IS NULL OR @identificacion <= 0
        THROW 50000, 'La identificación es obligatoria y debe ser > 0.', 1;
    -- acutalizar estado a 0 (inactivo)
    UPDATE dbo.Cliente
    SET estado = 0
    WHERE identificacion = @identificacion and estado = 1;

    IF @@ROWCOUNT = 0
        THROW 50000, 'Cliente no encontrado.', 1;
END
GO


SELECT * FROM Cliente;
GO

USE AltosDelValle;
GO


