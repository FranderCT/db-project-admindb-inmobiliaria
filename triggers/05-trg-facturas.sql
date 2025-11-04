-- TRIGGERS TABLA FACTURA


USE AltosDelValle;
GO

CREATE OR ALTER TRIGGER trg_GenerarCodigoFactura
ON dbo.Factura
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fechaActual DATE = CAST(GETDATE() AS DATE);
    DECLARE @anio INT = YEAR(@fechaActual);
    DECLARE @mes INT = MONTH(@fechaActual);
    DECLARE @prefijo BIGINT = @anio * 1000000 + @mes * 10000;

    DECLARE @ultimoConsecutivo INT;
    SELECT @ultimoConsecutivo = ISNULL(MAX(idFactura % 10000), 0)
    FROM Factura
    WHERE idFactura / 10000 = @prefijo / 10000;

    -- Insertar facturas con ID generado
    DECLARE @Factura TABLE (idFactura BIGINT, idContrato INT);

    INSERT INTO Factura (
        idFactura, montoPagado, fechaEmision, fechaPago, estadoPago,
        porcentajeIva, iva, idContrato, idAgente, idPropiedad,
        idTipoContrato, montoComision, porcentajeComision
    )
    OUTPUT inserted.idFactura, inserted.idContrato INTO @Factura
    SELECT
        @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @ultimoConsecutivo,
        montoPagado, ISNULL(fechaEmision, GETDATE()), fechaPago,
        ISNULL(estadoPago, 0), porcentajeIva, iva, idContrato, idAgente,
        idPropiedad, idTipoContrato, montoComision, porcentajeComision
    FROM inserted;

    
    INSERT INTO FacturaCliente (identificacion, idFactura)
    SELECT cc.identificacion, f.idFactura
    FROM @Factura f
    INNER JOIN Contrato c ON c.idContrato = f.idContrato
    INNER JOIN ClienteContrato cc ON cc.idContrato = c.idContrato;

END;
GO

