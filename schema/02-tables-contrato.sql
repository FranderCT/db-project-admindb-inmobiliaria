--			TABLA CONTRATO
USE AltosDelValle
GO




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
GO
