USE AltosDelValle
GO

CREATE OR ALTER TRIGGER trg_GenerarCodigoContrato
ON dbo.Contrato
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Obtener la fecha actual
    DECLARE @fechaActual DATE = CAST(GETDATE() AS DATE);
    DECLARE @anio INT = YEAR(@fechaActual);
    DECLARE @mes INT = MONTH(@fechaActual);
    DECLARE @dia INT = DAY(@fechaActual);
    
    -- Construir el prefijo: AAAAMMDD (ejemplo: 20251103)
    DECLARE @prefijo BIGINT = (@anio * 10000 + @mes * 100 + @dia) * 100; -- Multiplicar por 100 para dejar espacio al consecutivo
    
    -- Obtener el último consecutivo del día actual
    DECLARE @ultimoConsecutivo INT;
    
    SELECT 
        @ultimoConsecutivo = ISNULL(MAX(idContrato % 100), 0)
    FROM Contrato
    WHERE idContrato / 100 = @prefijo / 100; -- Comparar sin el consecutivo
    
    -- Insertar nuevos registros con ID generado
    INSERT INTO Contrato (
        idContrato,
        fechaInicio,
        fechaFin,
        fechaFirma,
        fechaPago,
        idTipoContrato,
        idPropiedad,
        idAgente,
        montoTotal,
        deposito,
        porcentajeComision,
        cantidadPagos,
        estado
    )
    SELECT 
        @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @ultimoConsecutivo,
        fechaInicio,
        fechaFin,
        fechaFirma,
        fechaPago,
        idTipoContrato,
        idPropiedad,
        idAgente,
        montoTotal,
        deposito,
        porcentajeComision,
        cantidadPagos,
        ISNULL(estado, 'Pendiente')
    FROM inserted;
    
    -- Mostrar los IDs generados (opcional, para debugging)
    SELECT 
        idContrato,
        fechaInicio,
        fechaFin,
        estado
    FROM Contrato
    WHERE idContrato IN (SELECT @prefijo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) + @ultimoConsecutivo FROM inserted);
END;
GO