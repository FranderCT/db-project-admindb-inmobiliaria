-- TRIGGERS TABLA CONTRATO
--Cada vez que se inserte un contrato nuevo, se genera su código con el formato CT-YYYYMM-####.
CREATE TRIGGER trg_contratoGeneraCodigo
ON Contrato
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fechaActual VARCHAR(6) = FORMAT(GETDATE(), 'yyyyMM');

    -- Obtener el último número consecutivo generado en el mes actual
    DECLARE @ultimoConsecutivo INT = ISNULL((
        SELECT MAX(CAST(RIGHT(codigoContrato, 4) AS INT))
        FROM Contrato
        WHERE SUBSTRING(codigoContrato, 4, 6) = @fechaActual
    ), 0);

    -- Insertar el nuevo código para cada fila insertada
    UPDATE c
    SET codigoContrato = 'CT-' + @fechaActual + '-' + 
                         RIGHT('0000' + CAST(@ultimoConsecutivo + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR(4)), 4)
    FROM Contrato c
    INNER JOIN inserted i ON c.idContrato = i.idContrato;
END;
GO

