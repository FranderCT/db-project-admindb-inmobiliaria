-- SP_INSERT 
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_insertContrato
    @fechaInicio   DATETIME,
    @fechaFin      DATETIME,
    @fechaFirma    DATETIME,
    @fechaPago     DATETIME,
    @idTipoContrato INT,
    @idPropiedad    INT,
    @idAgente       INT,
    @idCondicion    INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE 
            @existeTipo INT,
            @existePropiedad INT,
            @existeAgente INT,
            @existeCondicion INT;

        
        IF @fechaInicio IS NULL OR @fechaFin IS NULL OR @fechaFirma IS NULL OR @fechaPago IS NULL
        BEGIN
            PRINT 'Todas las fechas son obligatorias.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @fechaInicio > @fechaFin
        BEGIN
            PRINT 'La fecha de inicio no puede ser posterior a la fecha de fin.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @fechaFirma > @fechaInicio
        BEGIN
            PRINT 'La fecha de firma no puede ser posterior a la fecha de inicio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       

        SELECT @existeTipo = idTipoContrato
        FROM TipoContrato
        WHERE idTipoContrato = @idTipoContrato;

        IF @existeTipo IS NULL
        BEGIN
            PRINT 'No existe un tipo de contrato con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existePropiedad = idPropiedad
        FROM Propiedad
        WHERE idPropiedad = @idPropiedad;

        IF @existePropiedad IS NULL
        BEGIN
            PRINT 'No existe una propiedad con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existeAgente = idAgente
        FROM Agente
        WHERE idAgente = @idAgente;

        IF @existeAgente IS NULL
        BEGIN
            PRINT 'No existe un agente con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existeCondicion = idCondicion
        FROM Condicion
        WHERE idCondicion = @idCondicion;

        IF @existeCondicion IS NULL
        BEGIN
            PRINT 'No existe una condición con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       
        INSERT INTO Contrato
            (fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, idCondicion)
        VALUES
            (@fechaInicio, @fechaFin, @fechaFirma, @fechaPago, @idTipoContrato, @idPropiedad, @idAgente, @idCondicion);

        COMMIT TRANSACTION;
        PRINT 'Contrato registrado correctamente.';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_READ
USE AltosDelValle;
GO

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
            con.descripcion AS Condicion
        FROM Contrato c
            INNER JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
            INNER JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
            INNER JOIN Agente a ON c.idAgente = a.idAgente
            INNER JOIN Condicion con ON c.idCondicion = con.idCondicion
        WHERE c.idContrato = @_idContrato;

    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_UPDATE
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_updateContrato
    @_idContrato      INT,
    @_fechaInicio     DATETIME,
    @_fechaFin        DATETIME,
    @_fechaFirma      DATETIME,
    @_fechaPago       DATETIME,
    @_idTipoContrato  INT,
    @_idPropiedad     INT,
    @_idAgente        INT,
    @_idCondicion     INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE 
            @existeContrato   INT,
            @existeTipo       INT,
            @existePropiedad  INT,
            @existeAgente     INT,
            @existeCondicion  INT;

        
        SELECT @existeContrato = idContrato
        FROM Contrato
        WHERE idContrato = @_idContrato;

        IF @existeContrato IS NULL
        BEGIN
            PRINT 'No existe un contrato con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        
        IF @_fechaInicio IS NULL OR @_fechaFin IS NULL OR @_fechaFirma IS NULL OR @_fechaPago IS NULL
        BEGIN
            PRINT 'Todas las fechas son obligatorias.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       
        IF @_fechaInicio > @_fechaFin
        BEGIN
            PRINT 'La fecha de inicio no puede ser posterior a la fecha de fin.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @_fechaFirma > @_fechaInicio
        BEGIN
            PRINT 'La fecha de firma no puede ser posterior a la fecha de inicio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       

        SELECT @existeTipo = idTipoContrato
        FROM TipoContrato
        WHERE idTipoContrato = @_idTipoContrato;

        IF @existeTipo IS NULL
        BEGIN
            PRINT 'No existe un tipo de contrato con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existePropiedad = idPropiedad
        FROM Propiedad
        WHERE idPropiedad = @_idPropiedad;

        IF @existePropiedad IS NULL
        BEGIN
            PRINT 'No existe una propiedad con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existeAgente = idAgente
        FROM Agente
        WHERE idAgente = @_idAgente;

        IF @existeAgente IS NULL
        BEGIN
            PRINT 'No existe un agente con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        SELECT @existeCondicion = idCondicion
        FROM Condicion
        WHERE idCondicion = @_idCondicion;

        IF @existeCondicion IS NULL
        BEGIN
            PRINT 'No existe una condición con ese ID.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        
        UPDATE Contrato
        SET 
            fechaInicio   = @_fechaInicio,
            fechaFin      = @_fechaFin,
            fechaFirma    = @_fechaFirma,
            fechaPago     = @_fechaPago,
            idTipoContrato = @_idTipoContrato,
            idPropiedad    = @_idPropiedad,
            idAgente       = @_idAgente,
            idCondicion    = @_idCondicion
        WHERE idContrato = @_idContrato;

        COMMIT TRANSACTION;
        PRINT 'Contrato actualizado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_DELETE

