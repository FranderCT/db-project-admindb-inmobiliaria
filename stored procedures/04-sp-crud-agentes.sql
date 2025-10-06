-- SP_INSERT 
USE AltosDelValle
GO
create or alter procedure dbo.sp_InsertAgente
  @_nombre             varchar(30),
  @_apellido1          varchar(30),
  @_apellido2          varchar(30) = NULL,
  @_estado             bit,
  @_comisionInicial    decimal(18,2) = 0.00
as 
begin
	begin try
		begin transaction

		  if @_nombre is null or LTRIM(RTRIM(@_nombre)) = ''
			begin
				print 'El nombre es obligatorio.'; 
				rollback transaction;
				return;
			END

		  if @_apellido1 is null or LTRIM(RTRIM(@_apellido1)) = ''
			begin 
				print 'El primer apellido es obligatorio.'; 
				rollback transaction;
				return;
			end

		  if @_estado not in (0,1)
			begin 
				print 'El estado debe ser 0 o 1.'; 
				rollback transaction;
				return;
			end 

		  if @_comisionInicial is null or @_comisionInicial < 0
			begin 
				print 'La comisión inicial no puede ser negativa.'; 
				rollback transaction;
				return;
			end

		  insert into Agente (nombre, apellido1, apellido2, comisionAcumulada, estado)
		  values (@_nombre, @_apellido1, @_apellido2, @_comisionInicial, @_estado);

		commit transaction;
		print 'Agente agregado al sistema correctamente.';
	end try
  begin catch
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  end catch
end 
go


-- SP_READ
USE AltosDelValle
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

      select @existe = idAgente from Agente where idAgente = @_idAgente;
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
      where idAgente = @_idAgente;

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

		  select @existe = idAgente from Agente where idAgente = @_idAgente;
		  if @existe is null
			begin 
				print 'El agente no existe.'; 
				rollback transaction;
				return;
			end

		  update Agente
		  set estado = 0
		  where idAgente = @_idAgente;

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

      if not exists (select 1 from Agente where idAgente = @_idAgente)
		begin 
			print 'El agente no existe.'; 
			rollback transaction;
			return; 
		end

      update Agente
      set comisionAcumulada = comisionAcumulada + @_monto
      where idAgente = @_idAgente;
    commit transaction;
    print 'Comisión actualizada correctamente.';

  end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end
go
