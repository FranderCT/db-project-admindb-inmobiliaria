-- SP_INSERT 
USE AltosDelValle
GO
create or alter procedure dbo.sp_InsertAgente
  @_identificacion      INT, 
  @_nombre             varchar(30),
  @_apellido1          varchar(30),
  @_apellido2          varchar(30) = NULL,
  @_telefono            varchar(30)
  
as 
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    IF EXISTS (SELECT 1 FROM Agente WHERE identificacion = @_identificacion)
      THROW 50010, 'La identificación ya está registrada.', 1;
      
    IF @_identificacion IS NULL OR @_identificacion <= 0
      THROW 50011, 'La identificación es obligatoria y debe ser > 0.', 1;

    IF @_nombre IS NULL OR LTRIM(RTRIM(@_nombre)) = ''
      THROW 50012, 'El nombre es obligatorio.', 1;

    IF @_apellido1 IS NULL OR LTRIM(RTRIM(@_apellido1)) = ''
      THROW 50013, 'El primer apellido es obligatorio.', 1;

    IF @_telefono IS NULL OR LTRIM(RTRIM(@_telefono)) = ''
      THROW 50014, 'El teléfono es obligatorio.', 1;

    INSERT INTO Agente (identificacion, nombre, apellido1, apellido2, telefono)
    VALUES (@_identificacion, @_nombre, @_apellido1, @_apellido2, @_telefono);

    SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
    FROM Agente
    WHERE identificacion = @_identificacion;
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


-- SP_READ VER TODOS LOS AGENTES ACTIVOS
USE AltosDelValle
GO

CREATE OR ALTER PROCEDURE dbo.sp_AgenteLeerTodosActivos
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

CREATE OR ALTER PROCEDURE dbo.sp_AgenteLeerTodosInactivos
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

-- SP_UPDATE
USE AltosDelValle
GO
create or alter procedure sp_UpdateAgente
  @_idAgente    int,
  @_nombre      varchar(30),
  @_apellido1   varchar(30),
  @_apellido2   varchar(30) = NULL,
  @_estado      bit
as
begin
  begin try
    begin transaction
      declare @existe int;

      select @existe = identificacion from Agente where identificacion = @_idAgente;
      if @existe is null
		begin
			print 'El agente no existe.'; 
			rollback transaction;
			return;
		END

      if @_nombre is null or LTRIM(RTRIM(@_nombre)) = ''
		begin 
			print 'El nombre es obligatorio.'; 
			rollback transaction;
			return; 
		end

      if @_apellido1 is null or LTRIM(RTRIM(@_apellido1)) = ''
		BEGIN 
			print 'El primer apellido es obligatorio.';
			rollback transaction;
			return; 
		end

      if @_estado not in (0,1)
		begin 
			print 'El estado debe ser Activo (1) o inactivo (0).'; 
			rollback transaction;
			return;
		end

      update Agente
      set nombre    = @_nombre,
          apellido1 = @_apellido1,
          apellido2 = @_apellido2,
          estado    = @_estado
      where identificacion = @_idAgente;

    commit transaction
    print 'Agente actualizado correctamente.';
  end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end 
go

-- SP_DELETE
USE AltosDelValle
GO
create or alter procedure sp_DeleteAgente
  @_idAgente int
as
begin
	begin try
		begin transaction

		  declare @existe int;

		  select @existe = identificacion from Agente where identificacion = @_idAgente;
		  if @existe is null
			begin 
				print 'El agente no existe.'; 
				rollback transaction;
				return;
			end

		  update Agente
		  set estado = 0
		  where identificacion = @_idAgente;

		commit transaction;
		print 'Agente desactivado correctamente.';
	end try
	begin catch
		IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
		PRINT 'Error: ' + ERROR_MESSAGE();
	end catch
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

select * from Agente
go