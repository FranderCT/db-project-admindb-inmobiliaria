-- SP_INSERT 
USE AltosDelValle
GO
create or alter procedure dbo.sp_insertAgente
  @identificacion      INT, 
  @nombre             varchar(30),
  @apellido1          varchar(30),
  @apellido2          varchar(30) = NULL,
  @telefono            varchar(30)
  
as 
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    IF EXISTS (SELECT 1 FROM Agente WHERE identificacion = @identificacion)
      THROW 50010, 'La identificación ya está registrada.', 1;
      
    IF @identificacion IS NULL OR @identificacion <= 0
      THROW 50011, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
      THROW 50012, 'El nombre es obligatorio.', 1;

    IF @apellido1 IS NULL OR LTRIM(RTRIM(@apellido1)) = ''
      THROW 50013, 'El primer apellido es obligatorio.', 1;

    IF @telefono IS NULL OR LTRIM(RTRIM(@telefono)) = ''
      THROW 50014, 'El teléfono es obligatorio.', 1;

    INSERT INTO Agente (identificacion, nombre, apellido1, apellido2, telefono)
    VALUES (@identificacion, @nombre, @apellido1, @apellido2, @telefono);

    SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
    FROM Agente
    WHERE identificacion = @identificacion;
  END TRY
  BEGIN CATCH
    DECLARE @num INT = ERROR_NUMBER(),
            @msg NVARCHAR(4000) = ERROR_MESSAGE();

    -- Si es un error de nuestros códigos 50010..50099, relanzamos igual.
    IF @num BETWEEN 50010 AND 50099
      THROW @num, @msg, 1;

    -- Si es otro error (FK, CHECK, etc.), lo envolvemos en un mensaje genérico
    DECLARE @fullMsg NVARCHAR(4000) = N'Error al insertar agente: ' + @msg;
    THROW 50050, @fullMsg, 1;
  END CATCH
END
go

--SP_READ VER TODOS LOS AGENTES (TANTO ACTIVOS COMO INACTIVOS)
USE AltosDelValle
GO

CREATE OR ALTER PROCEDURE dbo.sp_viewAllAgentes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT
        identificacion,
        nombre,
        apellido1,
        apellido2,
        telefono,
        estado
    FROM dbo.Agente
END
GO


--SP_READ VER AGENTE POR SU ID
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_getByIdAgente
  @_identificacion INT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    IF @_identificacion IS NULL OR @_identificacion <= 0
      THROW 50030, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @_identificacion)
      THROW 50031, 'Agente no encontrado.', 1;

    SELECT 
      identificacion,
      nombre,
      apellido1,
      apellido2,
      telefono,
      comisionAcumulada,
      estado
    FROM Agente
    WHERE identificacion = @_identificacion;
  END TRY
  BEGIN CATCH
    DECLARE @num INT = ERROR_NUMBER(),
            @msg NVARCHAR(4000) = ERROR_MESSAGE();

    IF @num BETWEEN 50030 AND 50099
      THROW @num, @msg, 1;

    DECLARE @fullMsg NVARCHAR(4000) = N'Error al obtener agente: ' + @msg;
    THROW 50090, @fullMsg, 1;
  END CATCH
END
GO

-- SP_READ VER TODOS LOS AGENTES ACTIVOS
USE AltosDelValle
GO

CREATE OR ALTER PROCEDURE dbo.sp_viewAllActiveAgentes
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        identificacion,
        nombre,
        apellido1,
        apellido2,
        telefono,
        estado
    FROM dbo.Agente
    WHERE estado = 1; 
END
GO


-- SP_READ VER TODOS LOS AGENTES INACTIVOS

USE AltosDelValle
GO

CREATE OR ALTER PROCEDURE dbo.sp_viewAllInactiveAgentes
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        identificacion,
        nombre,
        apellido1,
        apellido2,
        telefono,
        estado
    FROM dbo.Agente
    WHERE estado = 0; 
END
GO

-- SP_READ VER TODOS LOS AGENTES (Identificacion y Nombre)

USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_nameListAgentes
  @_identificacion INT = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
   
    IF @_identificacion IS NOT NULL
    BEGIN
      IF @_identificacion <= 0
        THROW 50081, 'La identificación debe ser mayor a 0.', 1;

      SELECT 
        identificacion AS id, 
        nombre, 
        apellido1,
        apellido2
      FROM Agente
      WHERE identificacion = @_identificacion
      ORDER BY nombre ASC;

      RETURN;
    END

    SELECT 
      identificacion AS id, 
      nombre,
      apellido1,
      apellido2
    FROM Agente
    WHERE estado = 1
    ORDER BY nombre ASC;
  END TRY
  BEGIN CATCH
    DECLARE @num INT = ERROR_NUMBER(),
            @msg NVARCHAR(4000) = ERROR_MESSAGE();

    IF @num BETWEEN 50080 AND 50099
      THROW @num, @msg, 1;

    DECLARE @fullMsg NVARCHAR(4000) = N'Error al listar agentes: ' + @msg;
    THROW 50099, @fullMsg, 1;
  END CATCH
END
GO

--SP READ VER LOS CONTRATOS EN QUE HA PARTICIPADO UN AGENTE
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_getContratosPorAgente
  @idAgente BIGINT
AS
BEGIN
  SET NOCOUNT ON;

  -- Validar existencia del agente
  IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @idAgente)
  BEGIN
    RAISERROR('El agente especificado no existe.', 16, 1);
    RETURN;
  END;

  -- Seleccionar contratos del agente
  SELECT
      c.idContrato,
      tc.nombre AS tipoContrato,
      p.idPropiedad,
      p.ubicacion AS propiedadUbicacion,
      c.fechaInicio,
      c.fechaFin,
      c.fechaFirma,
      c.montoTotal,
      c.deposito,
      c.porcentajeComision,
      c.estado
  FROM Contrato c
  INNER JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
  INNER JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
  WHERE c.idAgente = @idAgente
  ORDER BY c.fechaInicio DESC;
END;
GO



-- SP_UPDATE
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_updateAgente
  @_identificacion INT,
  @_nombre         VARCHAR(30) = NULL,
  @_apellido1      VARCHAR(30) = NULL,
  @_apellido2      VARCHAR(30) = NULL,
  @_telefono       VARCHAR(30) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    
    IF @_identificacion IS NULL OR @_identificacion <= 0
      THROW 50020, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @_identificacion)
      THROW 50021, 'Agente no encontrado.', 1;

    UPDATE Agente
    SET 
      nombre = COALESCE(NULLIF(LTRIM(RTRIM(@_nombre)), ''), nombre),
      apellido1 = COALESCE(NULLIF(LTRIM(RTRIM(@_apellido1)), ''), apellido1),
      apellido2 = COALESCE(NULLIF(LTRIM(RTRIM(@_apellido2)), ''), apellido2),
      telefono = COALESCE(NULLIF(LTRIM(RTRIM(@_telefono)), ''), telefono)
    WHERE identificacion = @_identificacion;

    IF @@ROWCOUNT = 0
      THROW 50022, 'No se realizaron cambios en el registro.', 1;

    SELECT 
      identificacion, 
      nombre, 
      apellido1, 
      apellido2, 
      telefono, 
      comisionAcumulada, 
      estado
    FROM Agente
    WHERE identificacion = @_identificacion;
  END TRY

  BEGIN CATCH
    DECLARE @num INT = ERROR_NUMBER(),
            @msg NVARCHAR(4000) = ERROR_MESSAGE();

    IF @num BETWEEN 50020 AND 50099
      THROW @num, @msg, 1;

    DECLARE @fullMsg NVARCHAR(4000) = N'Error al actualizar agente: ' + @msg;
    THROW 50060, @fullMsg, 1;
  END CATCH
END
GO

-- SP_Update (Inactiva un Agente existente)
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_disableAgente
  @identificacion INT
AS
BEGIN
  SET NOCOUNT ON;

  IF @identificacion IS NULL OR @identificacion <= 0
    THROW 50071, 'La identificación es obligatoria y debe ser > 0.', 1;

  UPDATE dbo.Agente
  SET estado = 0
  WHERE identificacion = @identificacion AND estado = 1;

  IF @@ROWCOUNT = 0
    THROW 50072, 'Agente no encontrado o ya inactivo.', 1;
END
GO

-- SP_Update (Activa un Agente existente)
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_enableAgente
  @identificacion INT
AS
BEGIN
  SET NOCOUNT ON;

  IF @identificacion IS NULL OR @identificacion <= 0
    THROW 50073, 'La identificación es obligatoria y debe ser > 0.', 1;

  UPDATE dbo.Agente
  SET estado = 1
  WHERE identificacion = @identificacion AND estado = 0;

  IF @@ROWCOUNT = 0
    THROW 50074, 'Agente no encontrado o ya activo.', 1;
END
GO

-- SP_SUMARCOMISION
USE AltosDelValle
GO
create or alter procedure sp_SumarComisionAgente
  @_idAgente int,
  @_monto    decimal(18,2)
as
begin
  begin try
    begin transaction
      if @_monto IS NULL OR @_monto <= 0
		BEGIN 
			print 'El monto debe ser > 0.'; 
			rollback transaction;
			return;
		END

      if not exists (select 1 from Agente where identificacion = @_idAgente)
		begin 
			print 'El agente no existe.'; 
			rollback transaction;
			return; 
		end

      update Agente
      set comisionAcumulada = comisionAcumulada + @_monto
      where identificacion = @_idAgente;
    commit transaction;
    print 'Comisión actualizada correctamente.';

  end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end
go
