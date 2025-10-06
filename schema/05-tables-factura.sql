--			TABLA FACTURA
USE AltosDelValle
GO

create table Factura(

    idFactura int identity (1,1) not null,
    montoPagado money not null,
    fechaEmision datetime not null,
    estadoPago bit not null,
    iva money not null,
    idContrato int not null,
    idAgente int not null,
    montoComision money not null,
    porcentajeComision money not null

)On Facturas
GO



--    CONSTRAINTS

-- Primary Key

Alter table Factura
Add constraint pk_FacturaIdFactura
Primary key (idFactura)
GO


-- Foreign Key - Tipo Contrato

Alter table Factura
add constraint Fk_FacturaIdContrato
foreign key (idContrato)
references Contrato(idContrato)
GO


Alter table Factura
add constraint Fk_FacturaIdAgente
foreign key (idAgente)
references Agente(idAgente)
GO





--		CHECKS


--El monto pagado debe ser un valor positivo
Alter table Factura
Add constraint ck_Factura_MontoPagado_Positivo
CHECK (montoPagado >= 0);


--El IVA debe ser un valor positivo
Alter table Factura
Add constraint ck_Factura_Iva_Positivo
CHECK (iva >= 0);


--El monto de la comision debe ser un valor positivo
Alter table Factura
Add constraint  ck_Factura_MontoComision_Positivo
CHECK (montoComision >= 0);


--Las fechas de emisión no pueden exceder la fecha actual ni ser muy antiguas.
Alter table Factura
Add constraint ck_Factura_FechaEmision_Valida
CHECK (fechaEmision <= GETDATE() AND fechaEmision >= '2000-01-01');


--El estado de pago debe ser válido 0 (no pagado) o 1 (pagado)
Alter table Factura
Add constraint ck_Factura_EstadoPago_Valido
CHECK (estadoPago IN (0, 1));


-- Claves foráneas no nulas

Alter table Factura
Add constraint ck_Factura_IdContrato_Positivo
check (idContrato is null or idContrato > 0);


Alter table Factura
Add constraint ck_Factura_IdAgente_Positivo
check (idAgente is null or idAgente > 0);


--			TABLA FACTURACLIENTE