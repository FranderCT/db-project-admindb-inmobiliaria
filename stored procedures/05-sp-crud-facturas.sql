use AltosDelValle
go

-- SP_INSERT 
create or alter procedure sp_insertFactura
  @_montoPagado        MONEY,
  @_idContrato         INT,
  @_idAgente           INT,
  @_porcentajeComision DECIMAL(5,2),   -- ej: 5.00 = 5%
  @_porcentajeIVA      DECIMAL(5,2) = 13.00,
  @_idFactura          INT OUTPUT
as
begin
	begin try
		begin transaction
			declare @existeContrato int;
			declare @existeAgente int;
			declare @montoComision money;
			declare @iva money;

		  if @_montoPagado is null or @_montoPagado <= 0
			begin
				print 'El monto pagado debe ser mayor a 0.'; 
				rollback transaction;
				return
			end

		  if @_porcentajeComision is null or @_porcentajeComision < 0 or @_porcentajeComision > 100
			begin 
				print 'El porcentaje de comisión debe estar entre 0 y 100.'; 
				rollback transaction;
				return; 
			end

		  if @_porcentajeIVA is null or @_porcentajeIVA < 0 or @_porcentajeIVA > 100
			begin 
				print 'El porcentaje de IVA debe estar entre 0 y 100.'; 
				rollback transaction;
				return
			END

		  select @existeContrato = idContrato 
				from Contrato 
				where idContrato = @_idContrato;
		  if @existeContrato is null
			begin
				print 'El contrato no existe.'; 
				rollback transaction;
				return
			END

		  select @existeAgente = identificacion from Agente where identificacion = @_idAgente;
		  if @existeAgente is null
			begin 
				print 'El agente no existe.'; 
				rollback transaction;
				return
			END

		  set @iva = CONVERT(MONEY, ROUND(@_montoPagado * (@_porcentajeIVA / 100.0), 2));
		  set @montoComision = CONVERT(MONEY, ROUND(@_montoPagado * (@_porcentajeComision / 100.0), 2));

		  insert into Factura
			(montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision)
		  values
			(@_montoPagado, GETDATE(), 0, @iva, @_idContrato, @_idAgente, @montoComision, CONVERT(MONEY, @_porcentajeComision));

		  set @_idFactura = CONVERT(INT, SCOPE_IDENTITY());

		commit transaction

		print 'Factura creada correctamente. Su estado por defecto es pendiente.';
end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end 
go


-- SP_READ


-- SP_UPDATE
create or alter procedure sp_updateFactura
  @_idFactura          int,
  @_montoPagado        money,
  @_idContrato         int,
  @_idAgente           int,
  @_porcentajeComision decimal(5,2),
  @_porcentajeIVA      decimal(5,2) = 13.00
as
begin
  begin try
    begin transaction
      declare @existeFactura int;
	  declare @estadoPago BIT;
      declare @existeContrato int;
	  declare @existeAgente INT;
      declare @iva money;
	  declare @montoComision money;

      select @existeFactura = idFactura, @estadoPago = estadoPago
			from Factura where idFactura = @_idFactura;

      if @existeFactura IS NULL
		begin
			print 'La factura no existe.'; 
			
			rollback transaction;
			return
		end

      if @estadoPago = 1
	  begin
			print  'No se puede actualizar: la factura ya está pagada.';
			
			rollback transaction;
			return
		end

      if @_montoPagado is null or @_montoPagado <= 0
	  		begin
			print  'El montoPagado debe ser mayor a 0.'; 
			
			rollback transaction;
			return
		end

      if @_porcentajeComision is null or @_porcentajeComision < 0 or @_porcentajeComision > 100
	  		begin
			print  'El porcentaje de comisión debe estar entre 0 y 100.'; 
			
			rollback transaction;
			return
		end

      if @_porcentajeIVA is null or @_porcentajeIVA < 0 or @_porcentajeIVA > 100
	  		begin
			print 'El porcentaje de IVA debe estar entre 0 y 100.';
			
			rollback transaction;
			return
		end

      select @existeContrato = idContrato from Contrato where idContrato = @_idContrato;
      if @existeContrato is null
			BEGIN 
				print 'El contrato no existe.'; 
			rollback transaction;
			return
			END

      select @existeAgente = identificacion FROM dbo.Agente WHERE identificacion = @_idAgente;
      if @existeAgente IS NULL
		begin 
			PRINT 'El agente no existe.';
			rollback transaction;
			return
		end

      set @iva = CONVERT(MONEY, ROUND(@_montoPagado * (@_porcentajeIVA / 100.0), 2));
      set @montoComision = CONVERT(MONEY, ROUND(@_montoPagado * (@_porcentajeComision / 100.0), 2));

      update Factura
      set montoPagado        = @_montoPagado,
          iva                = @iva,
          idContrato         = @_idContrato,
          idAgente           = @_idAgente,
          montoComision      = @montoComision,
          porcentajeComision = CONVERT(MONEY, @_porcentajeComision)
      where idFactura = @_idFactura;

    commit transaction
    print 'Factura actualizada correctamente.';
end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end
go

-- SP_UPDATEESTADO
create or alter procedure sp_updateEstadoFactura
  @_idFactura int
as 
begin
  begin try
	begin transaction

      declare @estadoPago bit;
	  declare @idAgente int;
	  declare @montoComision MONEY;

      select @estadoPago = estadoPago,
             @idAgente   = idAgente,
             @montoComision = montoComision
      from Factura
      where idFactura = @_idFactura;

      if @estadoPago is null
		begin print 'La factura no existe.'; 
			rollback transaction;
			return
		end

      if @estadoPago = 1
		begin
			print 'La factura ya está pagada.'; 
			rollback transaction;
			return
		end

      update Factura
      set estadoPago = 1
      where idFactura = @_idFactura;

      update Agente
      set comisionAcumulada = comisionAcumulada + @montoComision
      where identificacion = @idAgente;

    commit transaction
    print 'Factura marcada como pagada y comisión aplicada al agente.';
end try
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    PRINT 'Error: ' + ERROR_MESSAGE();
  END CATCH
end
go
