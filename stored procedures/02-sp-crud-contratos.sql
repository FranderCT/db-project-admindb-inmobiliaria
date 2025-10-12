-- SP_INSERT 
CREATE OR ALTER PROCEDURE sp_insertContratoConNuevasCondiciones
    @fechaInicio DATETIME,
    @fechaFin DATETIME,
    @fechaFirma DATETIME,
    @fechaPago DATETIME,
    @idTipoContrato INT,
    @idPropiedad INT,
    @idAgente INT,
    @condiciones NVARCHAR(MAX)  -- JSON con los textos de condiciones
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ✅ Validaciones básicas
        IF @fechaInicio IS NULL OR @fechaFin IS NULL OR @fechaFirma IS NULL OR @fechaPago IS NULL
            THROW 50001, 'Todas las fechas son obligatorias.', 1;

        IF @fechaInicio > @fechaFin
            THROW 50002, 'La fecha de inicio no puede ser posterior a la fecha de fin.', 1;

        IF @fechaFirma > @fechaInicio
            THROW 50003, 'La fecha de firma no puede ser posterior a la fecha de inicio.', 1;

        IF NOT EXISTS (SELECT 1 FROM TipoContrato WHERE idTipoContrato = @idTipoContrato)
            THROW 50004, 'Tipo de contrato no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM Propiedad WHERE idPropiedad = @idPropiedad)
            THROW 50005, 'Propiedad no existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @idAgente)
            THROW 50006, 'Agente no existe.', 1;

        -- ✅ Insertar contrato
        DECLARE @idContrato INT;

        INSERT INTO Contrato (
            fechaInicio, fechaFin, fechaFirma, fechaPago,
            idTipoContrato, idPropiedad, idAgente
        )
        VALUES (
            @fechaInicio, @fechaFin, @fechaFirma, @fechaPago,
            @idTipoContrato, @idPropiedad, @idAgente
        );

        SET @idContrato = SCOPE_IDENTITY();

        -- Insertar condiciones (desde JSON)
        DECLARE @tmpCondiciones TABLE (texto NVARCHAR(255));  --  nombre único para evitar conflictos

        INSERT INTO @tmpCondiciones (texto)
        SELECT value
        FROM OPENJSON(@condiciones);

        DECLARE @texto NVARCHAR(255);
        DECLARE @idCondicion INT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT texto FROM @tmpCondiciones;

        OPEN cur;
        FETCH NEXT FROM cur INTO @texto;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Insertar texto de condición
            INSERT INTO TerminosCondiciones (textoCondicion)
            VALUES (@texto);

            SET @idCondicion = SCOPE_IDENTITY();

            -- Enlazar contrato con la condición
            INSERT INTO ContratoTerminos (idContrato, idCondicion)
            VALUES (@idContrato, @idCondicion);

            FETCH NEXT FROM cur INTO @texto;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT TRANSACTION;

        SELECT 
            @idContrato AS idContrato,
            'Contrato creado correctamente con nuevas condiciones' AS mensaje;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO


-- SP_READ
CREATE OR ALTER PROCEDURE sp_consultarContrato
    @_idContrato INT
AS
BEGIN
    BEGIN TRY

        IF NOT EXISTS (SELECT 1 FROM Contrato WHERE idContrato = @_idContrato)
        BEGIN
            PRINT 'No existe un contrato con ese ID.';
            RETURN;
        END

        SELECT 
            c.idContrato,
            c.fechaInicio,
            c.fechaFin,
            c.fechaFirma,
            c.fechaPago,
            tc.nombre AS TipoContrato,
            p.ubicacion AS Propiedad,
            a.nombre AS NombreAgente,
            a.apellido1 AS ApellidoAgente,
            tc2.textoCondicion AS Condicion
        FROM Contrato c
            INNER JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
            INNER JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
            INNER JOIN Agente a ON c.idAgente = a.identificacion
            INNER JOIN ContratoTerminos ct ON c.idContrato = ct.idContrato
            INNER JOIN TerminosCondiciones tc2 ON ct.idCondicion = tc2.idCondicion
        WHERE c.idContrato = @_idContrato;

    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_UPDATE                        
CREATE OR ALTER PROCEDURE sp_updateContratoConCondiciones
    @_idContrato      INT,
    @_fechaInicio     DATETIME,
    @_fechaFin        DATETIME,
    @_fechaFirma      DATETIME,
    @_fechaPago       DATETIME,
    @_idTipoContrato  INT,
    @_idPropiedad     INT,
    @_idAgente        INT,
    @_condiciones     NVARCHAR(MAX)  -- JSON con textos nuevos
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 🔎 Validar existencia
        IF NOT EXISTS (SELECT 1 FROM Contrato WHERE idContrato = @_idContrato)
            THROW 50010, 'No existe un contrato con ese ID.', 1;

        -- 🔎 Validaciones de fechas
        IF @_fechaInicio IS NULL OR @_fechaFin IS NULL OR @_fechaFirma IS NULL OR @_fechaPago IS NULL
            THROW 50011, 'Todas las fechas son obligatorias.', 1;

        IF @_fechaInicio > @_fechaFin
            THROW 50012, 'La fecha de inicio no puede ser posterior a la fecha de fin.', 1;

        IF @_fechaFirma > @_fechaInicio
            THROW 50013, 'La fecha de firma no puede ser posterior a la fecha de inicio.', 1;

        --  Actualizar datos del contrato
        UPDATE Contrato
        SET 
            fechaInicio    = @_fechaInicio,
            fechaFin       = @_fechaFin,
            fechaFirma     = @_fechaFirma,
            fechaPago      = @_fechaPago,
            idTipoContrato = @_idTipoContrato,
            idPropiedad    = @_idPropiedad,
            idAgente       = @_idAgente
        WHERE idContrato = @_idContrato;

        -- Eliminar vínculos antiguos en ContratoTerminos
        DELETE FROM ContratoTerminos WHERE idContrato = @_idContrato;

        -- (Opcional) eliminar condiciones viejas si no están asociadas a otros contratos
        -- DELETE FROM TerminosCondiciones
        -- WHERE idCondicion NOT IN (SELECT idCondicion FROM ContratoTerminos);

        -- Insertar nuevas condiciones desde JSON
        DECLARE @tmpCondiciones TABLE (texto NVARCHAR(255));
        INSERT INTO @tmpCondiciones (texto)
        SELECT value FROM OPENJSON(@_condiciones);

        DECLARE @texto NVARCHAR(255);
        DECLARE @idCondicion INT;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT texto FROM @tmpCondiciones;

        OPEN cur;
        FETCH NEXT FROM cur INTO @texto;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Insertar nuevo texto en TerminosCondiciones
            INSERT INTO TerminosCondiciones (textoCondicion)
            VALUES (@texto);

            SET @idCondicion = SCOPE_IDENTITY();

            -- Enlazar al contrato
            INSERT INTO ContratoTerminos (idContrato, idCondicion)
            VALUES (@_idContrato, @idCondicion);

            FETCH NEXT FROM cur INTO @texto;
        END

        CLOSE cur;
        DEALLOCATE cur;

        COMMIT TRANSACTION;

        SELECT 
            @_idContrato AS idContrato,
            'Contrato y condiciones actualizados correctamente' AS mensaje;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- SP_DELETE


-----   sp_consultarContratosConCondiciones
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
                tc.nombre AS TipoContrato,
                p.ubicacion AS Propiedad,
                a.nombre AS NombreAgente,
                a.apellido1 AS ApellidoAgente,
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
        ) AS data; -- 👈 alias para el JSON
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO




--TABLA TIPO CONTRATO 
INSERT INTO TipoContrato (nombre) VALUES ('Venta'), ('Alquiler');
GO

---TABLA TIPO CONTRATOS

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


---sp_updateTipoContrato
CREATE OR ALTER PROCEDURE sp_updateTipoContrato
  @idTipoContrato INT,
  @nombre VARCHAR(20)
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM TipoContrato WHERE idTipoContrato = @idTipoContrato)
      THROW 50010, 'No existe un tipo de contrato con ese ID.', 1;

    UPDATE TipoContrato
    SET nombre = @nombre
    WHERE idTipoContrato = @idTipoContrato;

    COMMIT TRANSACTION;
    SELECT @idTipoContrato AS idTipoContrato, 'Tipo de contrato actualizado correctamente' AS mensaje;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END;
GO


---sp_deleteTipoContrato
CREATE OR ALTER PROCEDURE sp_deleteTipoContrato
  @idTipoContrato INT
AS
BEGIN
  BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM TipoContrato WHERE idTipoContrato = @idTipoContrato)
      THROW 50020, 'No existe un tipo de contrato con ese ID.', 1;

    DELETE FROM TipoContrato WHERE idTipoContrato = @idTipoContrato;

    COMMIT TRANSACTION;
    SELECT @idTipoContrato AS idTipoContrato, 'Tipo de contrato eliminado correctamente' AS mensaje;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
  END CATCH
END;
GO


SELECT * FROM TipoContrato

ALTER TABLE Contrato DROP COLUMN idCondicion;

-- Eliminar restricción CHECK si existe
ALTER TABLE Contrato
DROP CONSTRAINT CK_Contrato_IdCondicion_Pos;
GO

-- Eliminar FOREIGN KEY que apunta a TerminosCondiciones
ALTER TABLE Contrato
DROP CONSTRAINT Fk_ContratoIdCondicion;
GO

