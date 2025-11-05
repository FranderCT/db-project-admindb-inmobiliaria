-- =====================================================
-- SCRIPT DE INSERTS USANDO STORED PROCEDURES
-- BD ALTOSDELVALLE - Usando SPs para garantizar validaciones
-- =====================================================

USE AltosDelValle;
GO

PRINT '========================================';
PRINT 'INICIANDO CARGA DE DATOS CON SPs';
PRINT '========================================';
GO

-- =====================================================
-- PASO 1: LIMPIAR DATOS EXISTENTES (en orden inverso a FKs)
-- =====================================================
PRINT 'Paso 1/11: Limpiando datos existentes...';
GO

-- Tablas dependientes primero
DELETE FROM Comision;
DELETE FROM FacturaCliente;
DELETE FROM Factura;
DELETE FROM ContratoTerminos;
DELETE FROM ClienteContrato;
DELETE FROM Contrato;
DELETE FROM Propiedad;
DELETE FROM Cliente;
DELETE FROM Agente;

-- Tablas maestras
DELETE FROM TerminosCondiciones;
DELETE FROM TipoContrato;
DELETE FROM TipoRol;
DELETE FROM TipoInmueble;
DELETE FROM EstadoPropiedad;
GO

PRINT 'Paso 1/11: Datos limpiados exitosamente.';
GO

-- =====================================================
-- PASO 2: REINICIAR IDENTITIES
-- =====================================================
PRINT 'Paso 2/11: Reiniciando identities...';
GO

DBCC CHECKIDENT ('TipoRol', RESEED, 0);
DBCC CHECKIDENT ('TipoContrato', RESEED, 0);
DBCC CHECKIDENT ('TerminosCondiciones', RESEED, 0);
DBCC CHECKIDENT ('EstadoPropiedad', RESEED, 0);
DBCC CHECKIDENT ('TipoInmueble', RESEED, 0);
DBCC CHECKIDENT ('ClienteContrato', RESEED, 0);
DBCC CHECKIDENT ('ContratoTerminos', RESEED, 0);
DBCC CHECKIDENT ('FacturaCliente', RESEED, 0);
DBCC CHECKIDENT ('Comision', RESEED, 0);
GO

PRINT 'Paso 2/11: Identities reiniciados.';
GO

-- =====================================================
-- PASO 3: INSERTAR DATOS MAESTROS (con SPs donde existan)
-- =====================================================
PRINT 'Paso 3/11: Insertando datos maestros...';
GO

-- TipoRol (no tiene SP, inserción directa)
INSERT INTO TipoRol (nombre) VALUES 
  ('Propietario'),
  ('Comprador'),
  ('Inquilino'),
  ('Arrendatario');
PRINT '  - TipoRol: 4 registros';
GO

-- TipoContrato (no tiene SP, inserción directa)
-- IMPORTANTE: Los nombres deben coincidir con los que espera sp_insertFactura: 'Venta' y 'Alquiler'
INSERT INTO TipoContrato (nombre) VALUES 
  ('Venta'),
  ('Alquiler'),
  ('Alquiler Temporal');
PRINT '  - TipoContrato: 3 registros';
GO

-- TerminosCondiciones (no tiene SP, inserción directa)
INSERT INTO TerminosCondiciones (textoCondicion) VALUES 
  ('El comprador acepta recibir la propiedad en el estado actual sin garantías adicionales.'),
  ('El arrendatario se compromete a pagar mensualidades los primeros 5 días de cada mes.'),
  ('Cualquier daño a la propiedad será responsabilidad del inquilino.'),
  ('El contrato puede ser rescindido con 30 días de anticipación por escrito.'),
  ('El depósito de garantía será devuelto dentro de 15 días tras la finalización del contrato.'),
  ('Prohibido subarrendar sin consentimiento del propietario.');
PRINT '  - TerminosCondiciones: 6 registros';
GO

-- EstadoPropiedad (usando SP)
EXEC sp_insertEstadoPropiedad @nombre = 'Disponible';
EXEC sp_insertEstadoPropiedad @nombre = 'Vendida';
EXEC sp_insertEstadoPropiedad @nombre = 'Alquilada';
EXEC sp_insertEstadoPropiedad @nombre = 'En Mantenimiento';
EXEC sp_insertEstadoPropiedad @nombre = 'Reservada';
PRINT '  - EstadoPropiedad: 5 registros (usando SP)';
GO

-- TipoInmueble (usando SP)
EXEC sp_tipoInmuebleInsertar @nombre = 'Casa';
EXEC sp_tipoInmuebleInsertar @nombre = 'Apartamento';
EXEC sp_tipoInmuebleInsertar @nombre = 'Local Comercial';
EXEC sp_tipoInmuebleInsertar @nombre = 'Terreno';
EXEC sp_tipoInmuebleInsertar @nombre = 'Bodega';
EXEC sp_tipoInmuebleInsertar @nombre = 'Oficina';
PRINT '  - TipoInmueble: 6 registros (usando SP)';
GO

PRINT 'Paso 3/11: Datos maestros insertados exitosamente.';
GO

-- =====================================================
-- PASO 4: INSERTAR CLIENTES (usando SP)
-- =====================================================
PRINT 'Paso 4/11: Insertando clientes...';
GO

EXEC dbo.sp_insertCliente @identificacion = 504440503, @nombre = 'Juan', @apellido1 = 'Pérez', @apellido2 = 'González', @telefono = 88776655;
EXEC dbo.sp_insertCliente @identificacion = 604550604, @nombre = 'María', @apellido1 = 'Rodríguez', @apellido2 = 'López', @telefono = 87654321;
EXEC dbo.sp_insertCliente @identificacion = 703660705, @nombre = 'Carlos', @apellido1 = 'Jiménez', @apellido2 = NULL, @telefono = 89012345;
EXEC dbo.sp_insertCliente @identificacion = 802770806, @nombre = 'Ana', @apellido1 = 'Martínez', @apellido2 = 'Castro', @telefono = 86543210;
EXEC dbo.sp_insertCliente @identificacion = 901880907, @nombre = 'Luis', @apellido1 = 'Hernández', @apellido2 = 'Mora', @telefono = 85432109;
EXEC dbo.sp_insertCliente @identificacion = 102990108, @nombre = 'Sofía', @apellido1 = 'Vargas', @apellido2 = 'Ramírez', @telefono = 84321098;
EXEC dbo.sp_insertCliente @identificacion = 203101209, @nombre = 'Diego', @apellido1 = 'Sánchez', @apellido2 = NULL, @telefono = 83210987;
EXEC dbo.sp_insertCliente @identificacion = 304211310, @nombre = 'Laura', @apellido1 = 'Gómez', @apellido2 = 'Solano', @telefono = 82109876;
GO

PRINT 'Paso 4/11: 8 clientes insertados (usando SP).';
GO

-- =====================================================
-- PASO 5: INSERTAR AGENTES (usando SP)
-- =====================================================
PRINT 'Paso 5/11: Insertando agentes...';
GO

EXEC dbo.sp_insertAgente @identificacion = 111222333, @nombre = 'Roberto', @apellido1 = 'Alvarado', @apellido2 = 'Ruiz', @telefono = 70001111;
EXEC dbo.sp_insertAgente @identificacion = 222333444, @nombre = 'Patricia', @apellido1 = 'Morales', @apellido2 = 'Vega', @telefono = 70002222;
EXEC dbo.sp_insertAgente @identificacion = 333444555, @nombre = 'Fernando', @apellido1 = 'Castro', @apellido2 = NULL, @telefono = 70003333;
GO

PRINT 'Paso 5/11: 3 agentes insertados (usando SP).';
GO

-- =====================================================
-- PASO 6: INSERTAR PROPIEDADES (usando SP)
-- =====================================================
PRINT 'Paso 6/11: Insertando propiedades...';
GO

-- Nota: sp_insertPropiedad usa el trigger trg_GenerarCodigoPropiedad que genera idPropiedad automáticamente

EXEC sp_insertPropiedad 
  @ubicacion = 'Av. Central 123, San José', 
  @precio = 185000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 1, 
  @identificacion = 504440503, 
  @imagenUrl = 'https://ejemplo.com/casa1.jpg', 
  @cantHabitaciones = 3, 
  @cantBannios = 2, 
  @areaM2 = 120.5, 
  @amueblado = 0;
  
EXEC sp_insertPropiedad 
  @ubicacion = 'Calle Los Laureles 45, Heredia', 
  @precio = 95000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 2, 
  @identificacion = 504440503, 
  @imagenUrl = 'https://ejemplo.com/apto1.jpg', 
  @cantHabitaciones = 2, 
  @cantBannios = 1, 
  @areaM2 = 75.0, 
  @amueblado = 1;

EXEC sp_insertPropiedad 
  @ubicacion = 'Boulevard del Este 789, Cartago', 
  @precio = 250000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 1, 
  @identificacion = 604550604, 
  @imagenUrl = 'https://ejemplo.com/casa2.jpg', 
  @cantHabitaciones = 4, 
  @cantBannios = 3, 
  @areaM2 = 200.0, 
  @amueblado = 0;

EXEC sp_insertPropiedad 
  @ubicacion = 'Centro Comercial Plaza 56, Alajuela', 
  @precio = 120000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 3, 
  @identificacion = 703660705, 
  @imagenUrl = NULL, 
  @cantHabitaciones = 1, 
  @cantBannios = 1, 
  @areaM2 = 80.0, 
  @amueblado = 0;

EXEC sp_insertPropiedad 
  @ubicacion = 'Residencial Los Pinos 22, Escazú', 
  @precio = 340000.00, 
  @idEstado = 2, 
  @idTipoInmueble = 1, 
  @identificacion = 802770806, 
  @imagenUrl = 'https://ejemplo.com/casa3.jpg', 
  @cantHabitaciones = 5, 
  @cantBannios = 4, 
  @areaM2 = 280.0, 
  @amueblado = 1;

EXEC sp_insertPropiedad 
  @ubicacion = 'Av. Segunda 101, San Pedro', 
  @precio = 65000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 2, 
  @identificacion = 901880907, 
  @imagenUrl = NULL, 
  @cantHabitaciones = 2, 
  @cantBannios = 1, 
  @areaM2 = 60.0, 
  @amueblado = 1;

EXEC sp_insertPropiedad 
  @ubicacion = 'Parque Industrial Norte lote 7', 
  @precio = 180000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 5, 
  @identificacion = 102990108, 
  @imagenUrl = NULL, 
  @cantHabitaciones = 1, 
  @cantBannios = 2, 
  @areaM2 = 150.0, 
  @amueblado = 0;

EXEC sp_insertPropiedad 
  @ubicacion = 'Edificio Empresarial piso 3 of 12', 
  @precio = 88000.00, 
  @idEstado = 1, 
  @idTipoInmueble = 6, 
  @identificacion = 203101209, 
  @imagenUrl = 'https://ejemplo.com/oficina1.jpg', 
  @cantHabitaciones = 1, 
  @cantBannios = 1, 
  @areaM2 = 45.0, 
  @amueblado = 1;
GO

PRINT 'Paso 6/11: 8 propiedades insertadas (usando SP).';
GO

-- =====================================================
-- PASO 7: INSERTAR CONTRATOS (usando SP con condiciones)
-- =====================================================
PRINT 'Paso 7/11: Insertando contratos...';
GO

-- Contrato 1: Venta de casa (idTipoContrato=1 es 'Venta')
DECLARE @idContrato1 INT;
EXEC sp_insertContratoConNuevasCondiciones
  @fechaInicio = '2025-01-15',
  @fechaFin = '2025-02-15',
  @fechaFirma = '2025-01-15',
  @fechaPago = '2025-01-20',
  @idTipoContrato = 1,
  @idPropiedad = 20250001,
  @idAgente = 111222333,
  @montoTotal = 185000.00,
  @deposito = 18500.00,
  @porcentajeComision = 3.50,
  @estado = 'Activo',
  @cantidadPagos = 1,
  @condiciones = '["Propiedad en estado actual sin garantías", "Rescisión con 30 días de anticipación"]';
GO

-- Contrato 2: Alquiler de apartamento (idTipoContrato=2 es 'Alquiler')
DECLARE @idContrato2 INT;
EXEC sp_insertContratoConNuevasCondiciones
  @fechaInicio = '2025-02-01',
  @fechaFin = '2026-02-01',
  @fechaFirma = '2025-02-01',
  @fechaPago = '2025-02-05',
  @idTipoContrato = 2,
  @idPropiedad = 20250002,
  @idAgente = 222333444,
  @montoTotal = 7200.00,
  @deposito = 1200.00,
  @porcentajeComision = 10.00,
  @estado = 'Activo',
  @cantidadPagos = 12,
  @condiciones = '["Pago mensual primeros 5 días", "Responsabilidad por daños", "Devolución depósito en 15 días", "Prohibido subarrendar"]';
GO

-- Contrato 3: Venta de casa grande (idTipoContrato=1 es 'Venta')
DECLARE @idContrato3 INT;
EXEC sp_insertContratoConNuevasCondiciones
  @fechaInicio = '2025-03-10',
  @fechaFin = '2025-04-10',
  @fechaFirma = '2025-03-10',
  @fechaPago = '2025-03-15',
  @idTipoContrato = 1,
  @idPropiedad = 20250003,
  @idAgente = 111222333,
  @montoTotal = 250000.00,
  @deposito = 25000.00,
  @porcentajeComision = 4.00,
  @estado = 'Pendiente',
  @cantidadPagos = 1,
  @condiciones = '["Propiedad vendida tal como se encuentra"]';
GO

PRINT 'Paso 7/11: 3 contratos insertados (usando SP con condiciones).';
GO

-- =====================================================
-- PASO 8: VINCULAR CLIENTES A CONTRATOS (usando SP)
-- =====================================================
PRINT 'Paso 8/11: Vinculando clientes a contratos...';
GO

-- IMPORTANTE: El trigger trg_GenerarCodigoContrato usa GETDATE() (fecha actual del servidor)
-- no las fechas del contrato. Por lo tanto, los IDs serán basados en HOY (05 nov 2025).
-- Formato: YYYYMMDDXX donde XX es el consecutivo
-- Hoy es 05-nov-2025, entonces: 2025110501, 2025110502, 2025110503

-- Obtener los IDs de contratos reales generados
DECLARE @idContrato1 INT, @idContrato2 INT, @idContrato3 INT;

SELECT @idContrato1 = MIN(idContrato) FROM Contrato;
SELECT @idContrato2 = MIN(idContrato) FROM Contrato WHERE idContrato > @idContrato1;
SELECT @idContrato3 = MAX(idContrato) FROM Contrato;

-- Contrato 1 (Compra-venta): Juan es propietario, María es compradora
IF @idContrato1 IS NOT NULL
BEGIN
  EXEC sp_insertClientesContrato @identificacion = 504440503, @idRol = 1, @idContrato = @idContrato1; -- Juan vende
  EXEC sp_insertClientesContrato @identificacion = 604550604, @idRol = 2, @idContrato = @idContrato1; -- María compra
END

-- Contrato 2 (Arrendamiento): Juan es propietario, Carlos es inquilino
IF @idContrato2 IS NOT NULL
BEGIN
  EXEC sp_insertClientesContrato @identificacion = 504440503, @idRol = 1, @idContrato = @idContrato2; -- Juan es propietario
  EXEC sp_insertClientesContrato @identificacion = 703660705, @idRol = 3, @idContrato = @idContrato2; -- Carlos es inquilino
END

-- Contrato 3 (Compra-venta): María es propietaria, Ana es compradora
IF @idContrato3 IS NOT NULL
BEGIN
  EXEC sp_insertClientesContrato @identificacion = 604550604, @idRol = 1, @idContrato = @idContrato3; -- María vende
  EXEC sp_insertClientesContrato @identificacion = 802770806, @idRol = 2, @idContrato = @idContrato3; -- Ana compra
END
GO

PRINT 'Paso 8/11: 6 relaciones cliente-contrato insertadas (usando SP).';
GO

-- =====================================================
-- PASO 9: CONTRATOTERMINOS (Ya manejado por el SP)
-- =====================================================
-- NOTA: El SP sp_insertContratoConNuevasCondiciones ya creó los términos
-- a partir del parámetro JSON @condiciones. No es necesario insertar manualmente.
PRINT 'Paso 9/11: Términos de contratos ya insertados por SP.';
GO


-- =====================================================
-- PASO 10: INSERTAR FACTURAS (usando SP)
-- =====================================================
PRINT 'Paso 10/11: Insertando facturas...';
GO

-- Nota: El SP sp_insertFactura calcula automáticamente todos los montos,
-- IVA, comisiones, y actualiza el estado de la propiedad según el tipo de contrato.
-- El trigger trg_GenerarCodigoFactura genera el idFactura y crea registros en FacturaCliente.

-- Obtener los IDs de contratos generados dinámicamente
DECLARE @idContrato1 INT, @idContrato2 INT, @idContrato3 INT;
SELECT @idContrato1 = MIN(idContrato) FROM Contrato;
SELECT @idContrato2 = MIN(idContrato) FROM Contrato WHERE idContrato > @idContrato1;
SELECT @idContrato3 = MAX(idContrato) FROM Contrato;

-- Factura para contrato 1 (Compra-venta)
DECLARE @idFactura1 BIGINT;
IF @idContrato1 IS NOT NULL
BEGIN
  EXEC sp_insertFactura 
    @idContrato = @idContrato1,
    @porcentajeIva = 13.00,
    @idFactura = @idFactura1 OUTPUT;
  PRINT 'Factura 1 generada con ID: ' + CAST(@idFactura1 AS VARCHAR);
END

-- Factura 1 para contrato 2 (Arrendamiento - primera mensualidad)
DECLARE @idFactura2 BIGINT;
IF @idContrato2 IS NOT NULL
BEGIN
  EXEC sp_insertFactura 
    @idContrato = @idContrato2,
    @porcentajeIva = 13.00,
    @idFactura = @idFactura2 OUTPUT;
  PRINT 'Factura 2 generada con ID: ' + CAST(@idFactura2 AS VARCHAR);
END

-- Factura 2 para contrato 2 (Arrendamiento - segunda mensualidad)
DECLARE @idFactura3 BIGINT;
IF @idContrato2 IS NOT NULL
BEGIN
  EXEC sp_insertFactura 
    @idContrato = @idContrato2,
    @porcentajeIva = 13.00,
    @idFactura = @idFactura3 OUTPUT;
  PRINT 'Factura 3 generada con ID: ' + CAST(@idFactura3 AS VARCHAR);
END

-- Factura para contrato 3 (Compra-venta)
DECLARE @idFactura4 BIGINT;
IF @idContrato3 IS NOT NULL
BEGIN
  EXEC sp_insertFactura 
    @idContrato = @idContrato3,
    @porcentajeIva = 13.00,
    @idFactura = @idFactura4 OUTPUT;
  PRINT 'Factura 4 generada con ID: ' + CAST(@idFactura4 AS VARCHAR);
END
GO

PRINT 'Paso 10/11: Facturas insertadas correctamente (usando SP).';
GO

-- =====================================================
-- PASO 11: COMISIONES (Creadas automáticamente)
-- =====================================================
-- NOTA: Las comisiones deben crearse automáticamente al momento del pago.
-- Para este script de inserción inicial, las comisiones se registran
-- manualmente solo cuando las facturas tienen montoComision > 0.
-- En producción, esto debería manejarse con un trigger o SP al pagar facturas.
PRINT 'Paso 11/11: Comisiones calculadas en facturas (pending trigger/SP for auto-insert).';
GO



-- =====================================================
-- VERIFICACIÓN DE DATOS INSERTADOS
-- =====================================================
PRINT '';
PRINT '========================================';
PRINT 'RESUMEN DE DATOS INSERTADOS:';
PRINT '========================================';
GO

SELECT 'TipoRol' AS Tabla, COUNT(*) AS Registros FROM TipoRol
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
SELECT 'Comision', COUNT(*) FROM Comision
ORDER BY Tabla;
GO

PRINT '';
PRINT '========================================';
PRINT 'Agentes registrados:';
PRINT '========================================';
GO

SELECT 
  identificacion,
  nombre + ' ' + apellido1 AS nombreCompleto,
  telefono,
  estado
FROM Agente
ORDER BY identificacion;
GO

PRINT '';
PRINT '========================================';
PRINT 'Script de inserts completado exitosamente!';
PRINT '========================================';
GO
