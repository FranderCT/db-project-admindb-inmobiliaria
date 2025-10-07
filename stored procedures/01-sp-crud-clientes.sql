USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_insertCliente
    @identificacion INT,
    @nombre     VARCHAR(30),
    @apellido1  VARCHAR(30),
    @apellido2  VARCHAR(30),
    @telefono   VARCHAR(30),
    @estado     BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF @identificacion IS NULL OR @identificacion <= 0
        BEGIN
            PRINT 'La identificación es obligatoria y debe ser mayor que 0.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        BEGIN
            PRINT 'El nombre es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @apellido1 IS NULL OR LTRIM(RTRIM(@apellido1)) = ''
        BEGIN
            PRINT 'El primer apellido es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @telefono IS NULL OR LTRIM(RTRIM(@telefono)) = ''
        BEGIN
            PRINT 'El teléfono es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        
        IF LEN(@telefono) < 8
        BEGIN
            PRINT 'El teléfono debe tener al menos 8 dígitos.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Cliente WHERE identificacion = @identificacion)
        BEGIN
            PRINT 'Ya existe un cliente con esa identificación.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       
        INSERT INTO Cliente (identificacion, nombre, apellido1, apellido2, telefono, estado)
        VALUES (@identificacion, @nombre, @apellido1, @apellido2, @telefono, @estado);

        COMMIT TRANSACTION;

        PRINT 'Cliente registrado correctamente.';

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

CREATE OR ALTER PROCEDURE sp_consultarCliente
    @_idCliente INT
AS
BEGIN
    BEGIN TRY
        
        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE idCliente = @_idCliente)
        BEGIN
            PRINT 'No existe un cliente asociado a ese ID.';
            RETURN;
        END

        -- Si existe, devolver la información del cliente
        SELECT 
            idCliente,
            nombre,
            apellido1,
            apellido2,
            telefono,
            CASE 
                WHEN estado = 1 THEN 'Activo' 
                ELSE 'Inactivo' 
            END AS estadoDescripcion
        FROM Cliente
        WHERE idCliente = @_idCliente;

    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_UPDATE
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_updateCliente
    @identificacion INT,
    @nombre         VARCHAR(30),
    @apellido1      VARCHAR(30),
    @apellido2      VARCHAR(30),
    @telefono       VARCHAR(30),
    @estado         BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @existeCliente INT;

        
        SELECT @existeCliente = identificacion
        FROM Cliente
        WHERE identificacion = @identificacion;

        IF @existeCliente IS NULL
        BEGIN
            PRINT 'No existe un cliente con esa identificación.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       
        IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        BEGIN
            PRINT 'El nombre es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @apellido1 IS NULL OR LTRIM(RTRIM(@apellido1)) = ''
        BEGIN
            PRINT 'El primer apellido es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @telefono IS NULL OR LTRIM(RTRIM(@telefono)) = ''
        BEGIN
            PRINT 'El teléfono es obligatorio.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF LEN(@telefono) < 8
        BEGIN
            PRINT 'El teléfono debe tener al menos 8 dígitos.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       
        IF @telefono LIKE '%[^0-9]%'
        BEGIN
            PRINT 'El teléfono debe contener solo números.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        
        UPDATE Cliente
        SET nombre     = @nombre,
            apellido1  = @apellido1,
            apellido2  = @apellido2,
            telefono   = @telefono,
            estado     = @estado
        WHERE identificacion = @identificacion;

        COMMIT TRANSACTION;

        PRINT 'Cliente actualizado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO


-- SP_INHABILITAR_CLIENTE

USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_inhabilitarCliente
    @_identificacion INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM Cliente WHERE identificacion = @_identificacion)
        BEGIN
            PRINT 'No existe un cliente con esa identificación.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Cliente WHERE identificacion = @_identificacion AND estado = 0)
        BEGIN
            PRINT 'El cliente ya está inhabilitado.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        UPDATE Cliente
        SET estado = 0
        WHERE identificacion = @_identificacion;

        COMMIT TRANSACTION;
        PRINT 'Cliente inhabilitado correctamente.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH
END;
GO
