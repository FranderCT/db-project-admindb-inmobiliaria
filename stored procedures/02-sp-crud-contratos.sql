use AltosDelValle
go

-- SP_INSERT 
CREATE OR ALTER PROCEDURE sp_insertContratoConNuevasCondiciones
    @fechaInicio DATETIME NULL,
    @fechaFin DATETIME NULL,
    @fechaFirma DATETIME NULL,
    @fechaPago DATETIME = NULL,
    @idTipoContrato INT,
    @idPropiedad INT,
    @idAgente INT,
    @montoTotal MONEY = NULL,
    @deposito MONEY = NULL,
    @porcentajeComision DECIMAL(5,2) = NULL,
    @estado NVARCHAR(20) = NULL,
    @cantidadPagos INT = NULL,
    @condiciones NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @idContrato INT;

        -- Estado automático
        IF @estado IS NULL
        BEGIN
            IF GETDATE() < @fechaInicio
                SET @estado = 'Pendiente';
            ELSE IF GETDATE() BETWEEN @fechaInicio AND @fechaFin
                SET @estado = 'Activo';
            ELSE
                SET @estado = 'Finalizado';
        END;


       -- Manejo seguro de las fechas

          IF TRY_CAST(@fechaInicio AS DATETIME) IS NULL
              SET @fechaInicio = NULL;

          IF TRY_CAST(@fechaFin AS DATETIME) IS NULL
              SET @fechaFin = NULL;

          IF TRY_CAST(@fechaFirma AS DATETIME) IS NULL
              SET @fechaFirma = NULL;

          IF TRY_CAST(@fechaPago AS DATETIME) IS NULL
              SET @fechaPago = NULL;

        INSERT INTO Contrato (
            fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente,
            montoTotal, deposito, porcentajeComision, estado, cantidadPagos
        )
        VALUES (
            @fechaInicio, @fechaFin, @fechaFirma, @fechaPago,
            @idTipoContrato, @idPropiedad, @idAgente,
            @montoTotal, @deposito, @porcentajeComision, @estado, @cantidadPagos
        );

        SET @idContrato = SCOPE_IDENTITY();

        -- Condiciones
        DECLARE @tmpCondiciones TABLE (texto NVARCHAR(255));
        INSERT INTO @tmpCondiciones (texto)
        SELECT value FROM OPENJSON(@condiciones);

        DECLARE @texto NVARCHAR(255), @idCondicion INT;
        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT texto FROM @tmpCondiciones;
        OPEN cur;
        FETCH NEXT FROM cur INTO @texto;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            INSERT INTO TerminosCondiciones (textoCondicion) VALUES (@texto);
            SET @idCondicion = SCOPE_IDENTITY();
            INSERT INTO ContratoTerminos (idContrato, idCondicion)
            VALUES (@idContrato, @idCondicion);
            FETCH NEXT FROM cur INTO @texto;
        END;
        CLOSE cur;
        DEALLOCATE cur;

        COMMIT TRANSACTION;
        SELECT @idContrato AS idContrato, 'Contrato creado correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        DECLARE 
            @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(),
            @ErrorSeverity INT = ERROR_SEVERITY(),
            @ErrorState INT = ERROR_STATE();

        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- SP_READ
-----   sp_consultarContratosConCondiciones (vista previa)
CREATE OR ALTER PROCEDURE sp_consultarContratosConCondiciones
    @idContrato INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT (
            SELECT 
                c.idContrato,
                c.fechaInicio,
                c.fechaFin,
                c.fechaFirma,
                c.fechaPago,

                -- IDs y relaciones
                c.idTipoContrato,
                tc.nombre AS TipoContrato,

                c.idPropiedad,
                p.ubicacion AS Propiedad,

                c.idAgente,
                a.nombre AS NombreAgente,
                a.apellido1 AS ApellidoAgente,

                c.estado,

                -- Condiciones del contrato
                (
                    SELECT 
                        t.idCondicion,
                        t.textoCondicion
                    FROM ContratoTerminos ct
                    INNER JOIN TerminosCondiciones t 
                        ON ct.idCondicion = t.idCondicion
                    WHERE ct.idContrato = c.idContrato
                    FOR JSON PATH
                ) AS condiciones

            FROM Contrato c
            INNER JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
            INNER JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
            INNER JOIN Agente a ON c.idAgente = a.identificacion
            WHERE (@idContrato IS NULL OR c.idContrato = @idContrato)
            FOR JSON PATH, INCLUDE_NULL_VALUES
        ) AS data;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- SP_UPDATE
CREATE OR ALTER PROCEDURE sp_updateContratoConCondiciones
    @_idContrato INT,
    @_fechaInicio DATETIME = NULL,
    @_fechaFin DATETIME = NULL,
    @_fechaFirma DATETIME = NULL,
    @_fechaPago DATETIME = NULL,
    @_idTipoContrato INT = NULL,
    @_idPropiedad INT = NULL,
    @_idAgente INT = NULL,
    @_montoTotal MONEY = NULL,
    @_deposito MONEY = NULL,
    @_porcentajeComision DECIMAL(5,2) = NULL,
    @_estado NVARCHAR(20) = NULL,
    @_cantidadPagos INT = NULL,
    @_condiciones NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE Contrato
        SET 
            fechaInicio = ISNULL(@_fechaInicio, fechaInicio),
            fechaFin = ISNULL(@_fechaFin, fechaFin),
            fechaFirma = ISNULL(@_fechaFirma, fechaFirma),
            fechaPago = ISNULL(@_fechaPago, fechaPago),
            idTipoContrato = ISNULL(@_idTipoContrato, idTipoContrato),
            idPropiedad = ISNULL(@_idPropiedad, idPropiedad),
            idAgente = ISNULL(@_idAgente, idAgente),
            montoTotal = ISNULL(@_montoTotal, montoTotal),
            deposito = ISNULL(@_deposito, deposito),
            porcentajeComision = ISNULL(@_porcentajeComision, porcentajeComision),
            estado = ISNULL(@_estado, estado),
            cantidadPagos = ISNULL(@_cantidadPagos, cantidadPagos)  
        WHERE idContrato = @_idContrato;

        -- Reemplazar condiciones si vienen nuevas
        IF @_condiciones IS NOT NULL
        BEGIN
            DELETE FROM ContratoTerminos WHERE idContrato = @_idContrato;

            DECLARE @tmpCondiciones TABLE (texto NVARCHAR(255));
            INSERT INTO @tmpCondiciones (texto)
            SELECT value FROM OPENJSON(@_condiciones);

            DECLARE @texto NVARCHAR(255), @idCondicion INT;
            DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT texto FROM @tmpCondiciones;
            OPEN cur;
            FETCH NEXT FROM cur INTO @texto;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                INSERT INTO TerminosCondiciones (textoCondicion) VALUES (@texto);
                SET @idCondicion = SCOPE_IDENTITY();
                INSERT INTO ContratoTerminos (idContrato, idCondicion)
                VALUES (@_idContrato, @idCondicion);
                FETCH NEXT FROM cur INTO @texto;
            END;
            CLOSE cur;
            DEALLOCATE cur;
        END;

        COMMIT TRANSACTION;
        SELECT @_idContrato AS idContrato, 'Contrato actualizado correctamente' AS mensaje;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

------   sp_detalleContrato (vista)
CREATE OR ALTER PROCEDURE dbo.sp_detalleContrato
  @idContrato INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @json NVARCHAR(MAX) = '';

  SELECT @json = (
    SELECT 
      c.idContrato, 
      c.fechaInicio, 
      c.fechaFin, 
      c.fechaFirma, 
      c.fechaPago,
      c.montoTotal, 
      c.deposito, 
      c.porcentajeComision, 
      c.cantidadPagos,
      c.estado,
      c.idTipoContrato, 
      tc.nombre AS tipoContrato,
      c.idPropiedad, 
      c.idAgente,

      -- Propiedad asociada
      JSON_QUERY((
        SELECT 
          p.idPropiedad, 
          p.ubicacion, 
          p.precio,
          ep.idEstadoPropiedad, 
          ep.nombre AS nombreEstadoPropiedad,
          ti.idTipoInmueble, 
          ti.nombre AS nombreTipoInmueble
        FROM dbo.Propiedad p
        INNER JOIN dbo.EstadoPropiedad ep ON ep.idEstadoPropiedad = p.idEstado
        INNER JOIN dbo.TipoInmueble ti ON ti.idTipoInmueble = p.idTipoInmueble
        WHERE p.idPropiedad = c.idPropiedad
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
      )) AS propiedad,

      -- Participantes del contrato
      JSON_QUERY((
        SELECT 
          cc.identificacion, 
          cl.nombre, 
          cl.apellido1, 
          cl.apellido2,
          tr.idRol, 
          tr.nombre AS rol
        FROM dbo.ClienteContrato cc
        INNER JOIN dbo.Cliente cl ON cl.identificacion = cc.identificacion
        INNER JOIN dbo.TipoRol tr ON tr.idRol = cc.idRol
        WHERE cc.idContrato = c.idContrato
        FOR JSON PATH
      )) AS participantes,

      -- Condiciones del contrato
      JSON_QUERY((
        SELECT 
          t.idCondicion, 
          t.textoCondicion
        FROM dbo.ContratoTerminos ct
        INNER JOIN dbo.TerminosCondiciones t ON t.idCondicion = ct.idCondicion
        WHERE ct.idContrato = c.idContrato
        FOR JSON PATH
      )) AS condiciones

    FROM dbo.Contrato c
    INNER JOIN dbo.TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
    WHERE c.idContrato = @idContrato
    FOR JSON PATH, INCLUDE_NULL_VALUES
  );

  IF @json IS NULL OR LEN(@json) = 0 SET @json = '[]';
  SELECT @json AS data;
END;
GO

------   sp_detalleGeneralContrato (todo el contenido de un contrato)
CREATE OR ALTER PROCEDURE dbo.sp_detalleGeneralContrato
  @idContrato INT  = NULL 
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @json NVARCHAR(MAX);

  SELECT @json = (
    SELECT 
      c.idContrato, 
      c.fechaInicio, 
      c.fechaFin, 
      c.fechaFirma, 
      c.fechaPago,
      c.montoTotal, 
      c.deposito, 
      c.porcentajeComision, 
      c.cantidadPagos,       
      c.estado,
      c.idTipoContrato, 
      tc.nombre AS tipoContrato,
      c.idPropiedad, 
      c.idAgente,

      -- Información de la propiedad
      JSON_QUERY((
        SELECT 
          p.idPropiedad, 
          p.ubicacion, 
          p.precio,
          ep.idEstadoPropiedad, 
          ep.nombre AS estadoPropiedad,
          ti.idTipoInmueble, 
          ti.nombre AS tipoInmueble,
          JSON_QUERY((
            SELECT 
              cli.identificacion, 
              cli.nombre, 
              cli.apellido1, 
              cli.apellido2, 
              cli.telefono, 
              cli.estado
            FROM dbo.Cliente cli
            WHERE cli.identificacion = p.identificacion
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
          )) AS cliente
        FROM dbo.Propiedad p
        INNER JOIN dbo.EstadoPropiedad ep ON ep.idEstadoPropiedad = p.idEstado
        INNER JOIN dbo.TipoInmueble ti ON ti.idTipoInmueble = p.idTipoInmueble
        WHERE p.idPropiedad = c.idPropiedad
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
      )) AS propiedad,

      -- Información del agente
      JSON_QUERY((
        SELECT 
          a.identificacion, 
          a.nombre, 
          a.apellido1, 
          a.apellido2, 
          a.comisionAcumulada
        FROM dbo.Agente a
        WHERE a.identificacion = c.idAgente
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
      )) AS agente,

      --  Participantes del contrato
      JSON_QUERY((
        SELECT 
          cl.identificacion, 
          cl.nombre, 
          cl.apellido1, 
          cl.apellido2, 
          tr.idRol, 
          tr.nombre AS rol
        FROM dbo.ClienteContrato cc
        INNER JOIN dbo.Cliente cl ON cl.identificacion = cc.identificacion
        INNER JOIN dbo.TipoRol tr ON tr.idRol = cc.idRol
        WHERE cc.idContrato = c.idContrato
        FOR JSON PATH
      )) AS participantes,

      --  Condiciones del contrato
      JSON_QUERY((
        SELECT 
          t.idCondicion, 
          t.textoCondicion
        FROM dbo.ContratoTerminos ct
        INNER JOIN dbo.TerminosCondiciones t ON t.idCondicion = ct.idCondicion
        WHERE ct.idContrato = c.idContrato
        FOR JSON PATH
      )) AS condiciones

    FROM dbo.Contrato c
    LEFT JOIN dbo.TipoContrato tc ON tc.idTipoContrato = c.idTipoContrato
    WHERE (@idContrato IS NULL OR c.idContrato = @idContrato)
    FOR JSON PATH, INCLUDE_NULL_VALUES
  );

  IF @json IS NULL OR LEN(@json) = 0 SET @json = '[]';
  SELECT @json AS data;
END;
GO

---TABLA TIPO CONTRATO
---sp_insertTipoContrato
CREATE OR ALTER PROCEDURE sp_insertTipoContrato
  @nombre VARCHAR(20)
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
      THROW 50001, 'El nombre del tipo de contrato es obligatorio.', 1;

    INSERT INTO TipoContrato (nombre)
    VALUES (@nombre);

    DECLARE @idTipoContrato INT = SCOPE_IDENTITY();

    COMMIT TRANSACTION;

    SELECT @idTipoContrato AS idTipoContrato, 'Tipo de contrato creado correctamente' AS mensaje;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END;
GO

---sp_consultarTipoContrato
CREATE OR ALTER PROCEDURE sp_consultarTipoContrato
  @idTipoContrato INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    SELECT 
      idTipoContrato,
      nombre
    FROM TipoContrato
    WHERE (@idTipoContrato IS NULL OR idTipoContrato = @idTipoContrato)
    FOR JSON PATH, INCLUDE_NULL_VALUES;
  END TRY
  BEGIN CATCH
    DECLARE @Error NVARCHAR(4000) = ERROR_MESSAGE();
    RAISERROR(@Error, 16, 1);
  END CATCH
END;
GO

--TABLA TIPO CONTRATO 
INSERT INTO TipoContrato (nombre) VALUES ('Venta'), ('Alquiler');
GO