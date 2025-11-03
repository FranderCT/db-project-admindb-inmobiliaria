-- SCRIPT PARA VACIAR TODAS LAS TABLAS Y HACER INSERTS CORREGIDOS
USE AltosDelValle;
GO

-- =============================================
-- VACIAR TODAS LAS TABLAS (EN ORDEN CORRECTO)
-- =============================================

-- Deshabilitar restricciones de foreign key temporalmente
EXEC sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL"
GO

-- Vaciar todas las tablas en orden inverso de dependencias
DELETE FROM Comision;
DELETE FROM FacturaCliente;
DELETE FROM Factura;
DELETE FROM ContratoTerminos;
DELETE FROM ClienteContrato;
DELETE FROM Contrato;
DELETE FROM Propiedad;
DELETE FROM Agente;
DELETE FROM Cliente;
DELETE FROM TipoInmueble;
DELETE FROM EstadoPropiedad;
DELETE FROM TerminosCondiciones;
DELETE FROM TipoContrato;
DELETE FROM TipoRol;

-- Reiniciar los contadores IDENTITY (solo las tablas que lo tienen)
DBCC CHECKIDENT ('TipoRol', RESEED, 0);
DBCC CHECKIDENT ('TipoContrato', RESEED, 0);
DBCC CHECKIDENT ('TerminosCondiciones', RESEED, 0);
DBCC CHECKIDENT ('EstadoPropiedad', RESEED, 0);
DBCC CHECKIDENT ('TipoInmueble', RESEED, 0);
DBCC CHECKIDENT ('Contrato', RESEED, 0);
DBCC CHECKIDENT ('ClienteContrato', RESEED, 0);
DBCC CHECKIDENT ('ContratoTerminos', RESEED, 0);
DBCC CHECKIDENT ('Factura', RESEED, 0);
DBCC CHECKIDENT ('FacturaCliente', RESEED, 0);
DBCC CHECKIDENT ('Comision', RESEED, 0);

-- Rehabilitar restricciones de foreign key
EXEC sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL"
GO

-- =============================================
-- INSERTS CORREGIDOS
-- =============================================

-- TIPO ROL (se inserta primero porque no tiene dependencias)
INSERT INTO TipoRol (nombre)
VALUES 
('Propietario'),
('Inquilino');
GO

-- TIPO CONTRATO
INSERT INTO TipoContrato (nombre)
VALUES 
('Venta'),
('Alquiler');
GO

-- TERMINOS CONDICIONES
INSERT INTO TerminosCondiciones (textoCondicion)
VALUES 
('Condiciones generales de venta'),
('Condiciones de alquiler');
GO

-- ESTADO PROPIEDAD
INSERT INTO EstadoPropiedad (nombre)
VALUES 
('Disponible'),
('Ocupada');
GO

-- TIPO INMUEBLE
INSERT INTO TipoInmueble (nombre)
VALUES 
('Casa'),
('Apartamento'),
('Oficina');
GO

-- CLIENTE (debe ir antes que Agente y Propiedad porque son referenciados)
INSERT INTO Cliente (identificacion, nombre, apellido1, apellido2, telefono, estado)
VALUES 
(12345678, 'Juan', 'Pérez', 'González', '8888-1234', 1),
(23456789, 'Ana', 'Martínez', 'Lopez', '8888-5678', 1),
(34567890, 'Luis', 'Fernández', 'Gutiérrez', '8888-2345', 1);
GO

-- AGENTE
INSERT INTO Agente (identificacion, nombre, apellido1, apellido2, telefono, comisionAcumulada, estado)
VALUES 
(87654321, 'Carlos', 'Ramírez', 'Hernández', '8888-9999', 5000.00, 1),
(76543210, 'Luis', 'González', 'Martínez', '8888-8888', 2000.00, 1),
(65432109, 'Marta', 'Rodríguez', 'Jiménez', '8888-7777', 3000.00, 1);
GO

-- PROPIEDAD (El trigger generará automáticamente los IDs tipo 20250001, 20250002, etc.)
-- NO especificamos idPropiedad, el trigger lo genera
DECLARE @propiedad1 INT, @propiedad2 INT, @propiedad3 INT;

INSERT INTO Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
VALUES ('Calle Falsa 123, San José', 150000.00, 1, 1, 12345678);

-- Obtener el ID generado por el trigger
SELECT @propiedad1 = MAX(idPropiedad) FROM Propiedad WHERE identificacion = 12345678;
PRINT 'Propiedad 1 ID: ' + CAST(@propiedad1 AS VARCHAR(10));

INSERT INTO Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
VALUES ('Avenida Central 456, Alajuela', 120000.00, 1, 2, 23456789);

SELECT @propiedad2 = MAX(idPropiedad) FROM Propiedad WHERE identificacion = 23456789;
PRINT 'Propiedad 2 ID: ' + CAST(@propiedad2 AS VARCHAR(10));

INSERT INTO Propiedad (ubicacion, precio, idEstado, idTipoInmueble, identificacion)
VALUES ('Calle Real 789, Heredia', 200000.00, 2, 3, 34567890);

SELECT @propiedad3 = MAX(idPropiedad) FROM Propiedad WHERE identificacion = 34567890;
PRINT 'Propiedad 3 ID: ' + CAST(@propiedad3 AS VARCHAR(10));

-- Verificar que las propiedades se insertaron correctamente
IF @propiedad1 IS NULL OR @propiedad2 IS NULL OR @propiedad3 IS NULL
BEGIN
    PRINT 'ERROR: No se pudieron insertar las propiedades correctamente';
    PRINT 'Propiedad1: ' + CAST(ISNULL(@propiedad1, -1) AS VARCHAR(10));
    PRINT 'Propiedad2: ' + CAST(ISNULL(@propiedad2, -1) AS VARCHAR(10));
    PRINT 'Propiedad3: ' + CAST(ISNULL(@propiedad3, -1) AS VARCHAR(10));
    RETURN;
END

PRINT 'Propiedades insertadas correctamente con IDs generados por trigger.';

-- CONTRATO (usar los IDs capturados de Propiedad)
DECLARE @contrato1 INT, @contrato2 INT, @contrato3 INT;

INSERT INTO Contrato (fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, cantidadPagos, estado)
VALUES ('2025-09-01', '2026-08-31', '2025-09-02', '2025-09-05', 1, @propiedad1, 87654321, 150000.00, 10000.00, 5.00, 12, 'Pendiente');
SET @contrato1 = SCOPE_IDENTITY();
PRINT 'Contrato 1 ID: ' + CAST(@contrato1 AS VARCHAR(10));

INSERT INTO Contrato (fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, cantidadPagos, estado)
VALUES ('2025-10-01', '2026-09-30', '2025-10-02', '2025-10-05', 2, @propiedad2, 76543210, 120000.00, 8000.00, 4.50, 12, 'Pendiente');
SET @contrato2 = SCOPE_IDENTITY();
PRINT 'Contrato 2 ID: ' + CAST(@contrato2 AS VARCHAR(10));

INSERT INTO Contrato (fechaInicio, fechaFin, fechaFirma, fechaPago, idTipoContrato, idPropiedad, idAgente, montoTotal, deposito, porcentajeComision, cantidadPagos, estado)
VALUES ('2025-10-15', '2026-10-14', '2025-10-16', '2025-10-20', 1, @propiedad3, 65432109, 200000.00, 12000.00, 6.00, 12, 'Pendiente');
SET @contrato3 = SCOPE_IDENTITY();
PRINT 'Contrato 3 ID: ' + CAST(@contrato3 AS VARCHAR(10));

-- CLIENTE CONTRATO
INSERT INTO ClienteContrato (identificacion, idRol, idContrato)
VALUES 
(12345678, 1, @contrato1),  -- Juan es Propietario del contrato 1
(23456789, 2, @contrato2),  -- Ana es Inquilino del contrato 2
(34567890, 1, @contrato3);  -- Luis es Propietario del contrato 3

PRINT 'ClienteContrato insertados correctamente.';

-- CONTRATO TERMINOS
INSERT INTO ContratoTerminos (idCondicion, idContrato)
VALUES 
(1, @contrato1),  -- Condiciones de venta para contrato 1
(2, @contrato2),  -- Condiciones de alquiler para contrato 2
(1, @contrato3);  -- Condiciones de venta para contrato 3

PRINT 'ContratoTerminos insertados correctamente.';

-- FACTURA
DECLARE @factura1 INT, @factura2 INT, @factura3 INT;

INSERT INTO Factura (montoPagado, fechaEmision, fechaPago, estadoPago, porcentajeIva, iva, idContrato, idAgente, idPropiedad, idTipoContrato, montoComision, porcentajeComision)
VALUES (10000.00, '2025-09-10', '2025-09-15', 1, 13.00, 1300.00, @contrato1, 87654321, @propiedad1, 1, 5000.00, 5.00);
SET @factura1 = SCOPE_IDENTITY();
PRINT 'Factura 1 ID: ' + CAST(@factura1 AS VARCHAR(10));

INSERT INTO Factura (montoPagado, fechaEmision, fechaPago, estadoPago, porcentajeIva, iva, idContrato, idAgente, idPropiedad, idTipoContrato, montoComision, porcentajeComision)
VALUES (8000.00, '2025-10-10', '2025-10-15', 1, 13.00, 1040.00, @contrato2, 76543210, @propiedad2, 2, 4000.00, 4.50);
SET @factura2 = SCOPE_IDENTITY();
PRINT 'Factura 2 ID: ' + CAST(@factura2 AS VARCHAR(10));

INSERT INTO Factura (montoPagado, fechaEmision, fechaPago, estadoPago, porcentajeIva, iva, idContrato, idAgente, idPropiedad, idTipoContrato, montoComision, porcentajeComision)
VALUES (12000.00, '2025-10-20', '2025-10-25', 1, 13.00, 1560.00, @contrato3, 65432109, @propiedad3, 1, 6000.00, 6.00);
SET @factura3 = SCOPE_IDENTITY();
PRINT 'Factura 3 ID: ' + CAST(@factura3 AS VARCHAR(10));

-- FACTURA CLIENTE
INSERT INTO FacturaCliente (identificacion, idFactura)
VALUES 
(12345678, @factura1),  -- Juan vinculado a factura 1
(23456789, @factura2),  -- Ana vinculada a factura 2
(34567890, @factura3);  -- Luis vinculado a factura 3

PRINT 'FacturaCliente insertados correctamente.';

-- COMISION
INSERT INTO Comision (idAgente, idFactura, idContrato, fechaComision, montoComision, porcentajeComision, estado)
VALUES 
(87654321, @factura1, @contrato1, '2025-09-10', 5000.00, 5.00, 1),
(76543210, @factura2, @contrato2, '2025-10-10', 4000.00, 4.50, 1),
(65432109, @factura3, @contrato3, '2025-10-20', 6000.00, 6.00, 1);

PRINT 'Comisiones insertadas correctamente.';
GO

-- =============================================
-- VERIFICACIÓN DE DATOS INSERTADOS
-- =============================================

PRINT '========================================';
PRINT 'VERIFICACIÓN DE DATOS INSERTADOS';
PRINT '========================================';

SELECT 'TipoRol' as Tabla, COUNT(*) as Registros FROM TipoRol
UNION ALL
SELECT 'TipoContrato', COUNT(*) FROM TipoContrato
UNION ALL
SELECT 'TerminosCondiciones', COUNT(*) FROM TerminosCondiciones
UNION ALL
SELECT 'EstadoPropiedad', COUNT(*) FROM EstadoPropiedad
UNION ALL
SELECT 'TipoInmueble', COUNT(*) FROM TipoInmueble
UNION ALL
SELECT 'Cliente', COUNT(*) FROM Cliente
UNION ALL
SELECT 'Agente', COUNT(*) FROM Agente
UNION ALL
SELECT 'Propiedad', COUNT(*) FROM Propiedad
UNION ALL
SELECT 'Contrato', COUNT(*) FROM Contrato
UNION ALL
SELECT 'ClienteContrato', COUNT(*) FROM ClienteContrato
UNION ALL
SELECT 'ContratoTerminos', COUNT(*) FROM ContratoTerminos
UNION ALL
SELECT 'Factura', COUNT(*) FROM Factura
UNION ALL
SELECT 'FacturaCliente', COUNT(*) FROM FacturaCliente
UNION ALL
SELECT 'Comision', COUNT(*) FROM Comision;

PRINT '';
PRINT 'CONTRATOS CREADOS:';
SELECT 
    idContrato, 
    FORMAT(fechaInicio, 'dd/MM/yyyy') as FechaInicio,
    idTipoContrato, 
    idPropiedad, 
    idAgente, 
    FORMAT(montoTotal, 'C', 'es-CR') as MontoTotal,
    estado 
FROM Contrato;

PRINT '';
PRINT 'PROPIEDADES (con IDs generados por trigger):';
SELECT 
    idPropiedad, 
    ubicacion, 
    FORMAT(precio, 'C', 'es-CR') as Precio,
    idEstado, 
    idTipoInmueble, 
    identificacion 
FROM Propiedad;

PRINT '';
PRINT 'FACTURAS:';
SELECT 
    idFactura, 
    FORMAT(montoPagado, 'C', 'es-CR') as MontoPagado,
    FORMAT(fechaEmision, 'dd/MM/yyyy') as FechaEmision,
    CASE WHEN estadoPago = 1 THEN 'Pagado' ELSE 'Pendiente' END as EstadoPago,
    idContrato, 
    idAgente, 
    idPropiedad 
FROM Factura;
GO



