-- TRIGGERS TABLA FACTURA


USE AltosDelValle;
GO

IF OBJECT_ID('dbo.trg_facturaComisionAgente', 'TR') IS NOT NULL
    DROP TRIGGER dbo.trg_facturaComisionAgente;
GO

CREATE TRIGGER dbo.trg_facturaComisionAgente
ON dbo.Factura
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Rango del mes actual (inclusive-exclusive) para evitar funciones sobre la columna
    DECLARE @IniMes DATE = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    DECLARE @IniMesSiguiente DATE = DATEADD(MONTH, 1, @IniMes);

    ;WITH agentes_afectados AS (
        SELECT DISTINCT i.idAgente
        FROM inserted i
    ),
    sumas_mes AS (
        SELECT f.idAgente, SUM(f.montoComision) AS totalMes
        FROM dbo.Factura f
        INNER JOIN agentes_afectados a ON a.idAgente = f.idAgente
        WHERE f.fechaEmision >= @IniMes
          AND f.fechaEmision <  @IniMesSiguiente
        GROUP BY f.idAgente
    )
    UPDATE a
        SET a.comisionAcumulada = ISNULL(s.totalMes, 0)
    FROM dbo.Agente a
    LEFT JOIN sumas_mes s
        ON s.idAgente = a.identificacion
    WHERE a.identificacion IN (SELECT idAgente FROM agentes_afectados);
END
GO


USE AltosDelValle;
GO

-- Insertar un cliente
INSERT INTO Cliente (identificacion, nombre, apellido1, telefono, estado)
VALUES (1, 'Juan', 'Pérez', '8888-8888', 1);

-- Insertar un agente
INSERT INTO Agente (identificacion, nombre, apellido1, apellido2, comisionAcumulada, estado)
VALUES (10, 'María', 'González', NULL, 0, 1);

-- Insertar registros base para Propiedad, TipoContrato, TerminosCondiciones
INSERT INTO TipoContrato (nombre) VALUES ('Alquiler');
INSERT INTO TerminosCondiciones (textoCondicion) VALUES ('Condiciones estándar');
INSERT INTO EstadoPropiedad (nombre) VALUES ('Disponible');
INSERT INTO TipoInmueble (nombre) VALUES ('Casa');

-- Propiedad asociada al cliente
INSERT INTO Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
VALUES ('San Pablo', 100000, 1, 1, 1);
GO


DECLARE @today DATE = GETDATE();

INSERT INTO Contrato (fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, idCondicion)
VALUES (
    @today,
    DATEADD(MONTH, 6, @today),
    @today,
    @today,
    1,   -- TipoContrato
    1,   -- Propiedad
    10,  -- Agente
    1    -- TerminosCondiciones
);
GO


-- FACTURA en el mes actual
INSERT INTO Factura (montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision)
VALUES (5000, GETDATE(), 1, 650, 1, 10, 500, 0.1);

-- FACTURA adicional en el mismo mes (para probar acumulado)
INSERT INTO Factura (montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision)
VALUES (7000, GETDATE(), 1, 910, 1, 10, 700, 0.1);

-- FACTURA en un mes diferente (para asegurar que no se suma al mes actual)
INSERT INTO Factura (montoPagado, fechaEmision, estadoPago, iva, idContrato, idAgente, montoComision, porcentajeComision)
VALUES (8000, DATEADD(MONTH, -1, GETDATE()), 1, 1040, 1, 10, 800, 0.1);
GO


-- Ver el total de comisiones acumuladas en el agente
SELECT identificacion, nombre, comisionAcumulada
FROM Agente
WHERE identificacion = 10;

-- Ver facturas creadas
SELECT idFactura, fechaEmision, montoComision
FROM Factura
WHERE idAgente = 10
ORDER BY fechaEmision DESC;
