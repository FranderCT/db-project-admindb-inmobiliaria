--			TABLA CONTRATO
USE AltosDelValle
GO
create table Contrato(
	idContrato int identity (1,1) not null,
	fechaInicio datetime not null, 
	fechaFin datetime not null, 
	fechaFirma datetime not null, 
	fechaPago datetime not null,
	idTipoContrato int not null,
	idPropiedad int not null, 
	idAgente int not null
)on Contratos
go


------ SE AGREGAN NUEVAS COLUMNAS A LA TABLA CONTRATO PARA GESTIONAR MONTOS Y COMISIONES
ALTER TABLE Contrato
ADD 
    montoTotal MONEY NULL,              -- precio final (venta) o mensualidad (alquiler)
    deposito MONEY NULL,                -- depósito (si aplica, solo en alquiler)
    porcentajeComision DECIMAL(5,2) NULL, -- porcentaje de comisión del agente ejemplo (5.00 = 5%)
    estado NVARCHAR(30) DEFAULT 'Pendiente'; -- estado del contrato (Pendiente, Activo, Finalizado, Cancelado)
GO

--		CONSTRAINTS

-- Primary Key
alter table Contrato
add constraint pk_ContratoIdContrato
primary key (idContrato)
go

-- Foreign Key - Tipo Contrato
alter table Contrato
add constraint Fk_ContratoIdTipoContrato
foreign key (idTipoContrato)
references TipoContrato(idTipoContrato)

-- Foreign Key - Propiedad
alter table Contrato
add constraint Fk_ContratoIdPropiedad
foreign key (idPropiedad)
references Propiedad(idPropiedad)

-- Foreign Key - Agente
alter table Contrato
add constraint Fk_ContratoIdAgente
foreign key (idAgente)
references Agente(idAgente)

-- Foreign Key - Condicion (Terminos y condiciones)
alter table Contrato
add constraint Fk_ContratoIdCondicion
foreign key (idCondicion)
references Condicion(idCondicion)



--		CHECKS
-- Fecha fin debe ser mayor o igual a la fecha fin 
alter table Contrato 
add constraint ck_ContratoFechasOrden
check (
	fechaInicio is null or
	fechaFin is null or
	fechaInicio <= fechaFin
);

-- Firma dentro del periodo del contrato
alter table Contrato 
add constraint ck_ContratoFirmaEnRango
check (
	fechaFirma is null or
	(
		(fechaInicio is null or fechaFirma >= fechaInicio) and
		(fechaFin is null or fechaFirma <= fechaFin)
	)
);

-- Pago no debe ser antes de fechaInicio o fechaFirma
alter table Contrato 
add constraint ck_ContratoPagoNoAntes
check (
	fechaPago is null or
	(
		(fechaInicio is null or fechaPago >= fechaInicio) and
		(fechaFirma  is null or fechaPago >= fechaFirma)
	)
);

-- Not null foreign keys
alter table Contrato 
add constraint  CK_Contrato_IdTipoContrato_Pos
check (idTipoContrato is null or idTipoContrato > 0);

alter table Contrato 
add constraint CK_Contrato_IdPropiedad_Pos
check (idPropiedad is null or idPropiedad > 0);

alter table Contrato 
add constraint CK_Contrato_IdAgente_Pos
check (idAgente is null or idAgente > 0);

alter table Contrato 
add constraint CK_Contrato_IdCondicion_Pos
check (idCondicion is null or idCondicion > 0);


-- TABLA TIPO CONTRATO
CREATE TABLE TipoContrato (
    idTipoContrato INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(20) NOT NULL
);
GO

-- TABLA TERMINOS CONDICIONES
CREATE TABLE TerminosCondiciones (
    idCondicion INT IDENTITY(1,1) PRIMARY KEY,
    textoCondicion VARCHAR(255) NOT NULL
);
GO

-- TABLA CONTRATO TERMINOS
CREATE TABLE ContratoTerminos (
    idContratoTerminos INT IDENTITY(1,1) PRIMARY KEY,
    idCondicion INT NOT NULL,
    idContrato INT NOT NULL
    -- Foreign keys
    CONSTRAINT FK_ContratoTerminos_TerminosCondiciones FOREIGN KEY (idCondicion) REFERENCES TerminosCondiciones(idCondicion),
    CONSTRAINT FK_ContratoTerminos_Contrato FOREIGN KEY (idContrato) REFERENCES Contrato(idContrato)
);



--			TABLA CONTRATO TERMINOS 
USE AltosDelValle
GO


--			TABLA TIPO CONTRATO
USE AltosDelValle
GO
