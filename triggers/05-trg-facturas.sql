-- TRIGGERS TABLA FACTURA


USE AltosDelValle;
GO

CREATE OR ALTER TRIGGER trg_GenerarCodigoFactura
ON dbo.Factura
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener la fecha actual
    DECLARE @fechaActual DATE = CAST(GETDATE() AS DATE);
    DECLARE @anio INT = YEAR(@fechaActual);
    DECLARE @mes INT = MONTH(@fechaActual);
    
    -- Construir el prefijo: AAAAMM (ejemplo: 202507)
    DECLARE @prefijo BIGINT = @anio * 1000000 + @mes * 10000;
    
    -- Obtener el último consecutivo del mes actual
    DECLARE @ultimoConsecutivo INT;
    
    SELECT 
        @ultimoConsecutivo = ISNULL(MAX(idFactura % 10000), 0)
    FROM Factura
    WHERE idFactura / 10000 = @prefijo / 10000; -- Comparar año y mes
    
    -- Insertar nuevos registros con ID generado
    INSERT INTO Factura (
        idFactura,
        montoPagado,
        fechaEmision,
        fechaPago,
        estadoPago,
        porcentajeIva,
        iva,
        idContrato,
        idAgente,
        idPropiedad,
        idTipoContrato,
        montoComision,
        porcentajeComision
    )
    SELECT 
        @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @ultimoConsecutivo,
        montoPagado,
        ISNULL(fechaEmision, GETDATE()),
        fechaPago,
        ISNULL(estadoPago, 0),
        porcentajeIva,
        iva,
        idContrato,
        idAgente,
        idPropiedad,
        idTipoContrato,
        montoComision,
        porcentajeComision
    FROM inserted;
    
    -- Mostrar las facturas generadas (opcional)
    PRINT 'Facturas generadas:';
    SELECT 
        idFactura,
        montoPagado,
        fechaEmision,
        idContrato,
        estadoPago
    FROM Factura
    WHERE idFactura >= @prefijo + @ultimoConsecutivo + 1 
      AND idFactura < @prefijo + @ultimoConsecutivo + 1 + (SELECT COUNT(*) FROM inserted);
END;
GO