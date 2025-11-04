
use AltosDelValle
GO

CREATE OR ALTER PROCEDURE  dbo.sp_contrato_historial_por_cliente
    @identificacion INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación mínima
    IF @identificacion IS NULL
    BEGIN
        RAISERROR('El parámetro @identificacion es obligatorio.', 16, 1);
        RETURN;
    END

    -- Comprueba si el cliente existe (opcional)
    IF NOT EXISTS (SELECT 1 FROM Cliente WHERE identificacion = @identificacion)
    BEGIN
        RAISERROR('Cliente con identificaci\u00f3n %d no existe.', 16, 1, @identificacion);
        RETURN;
    END

    -- Consulta principal: contratos vinculados al cliente mediante ClienteContrato
    SELECT
        cc.idClienteContrato,
        cc.identificacion,
        cli.nombre,
        cli.apellido1,
        cli.apellido2,
        cc.idRol,
        tr.nombre,
        c.idContrato,
        c.fechaInicio,
        c.fechaFin,
        c.fechaFirma,
        c.fechaPago,
        c.idTipoContrato,
        tc.nombre,
        c.idPropiedad,
        p.ubicacion,
        p.precio,
        c.idAgente,
        a.nombre,
        a.apellido1,
        a.apellido2,
        c.montoTotal,
        c.deposito,
        c.porcentajeComision,
        c.cantidadPagos,
        c.estado,
        ISNULL(f.factura_count, 0),
        ISNULL(f.total_pagado, 0),
        f.ultima_factura_emision,
        CASE WHEN p.identificacion = cc.identificacion THEN 'Propietario' ELSE 'Comprador' END
    FROM ClienteContrato cc
    INNER JOIN Contrato c ON cc.idContrato = c.idContrato
    LEFT JOIN Cliente cli ON cc.identificacion = cli.identificacion
    LEFT JOIN TipoRol tr ON cc.idRol = tr.idRol
    LEFT JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
    LEFT JOIN Agente a ON c.idAgente = a.identificacion
    LEFT JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
    LEFT JOIN (
        SELECT idContrato,
                COUNT(*) factura_count,
                SUM(montoPagado) total_pagado,
                MAX(fechaEmision) ultima_factura_emision
        FROM Factura
        GROUP BY idContrato
    ) f ON c.idContrato = f.idContrato
    WHERE cc.identificacion = @identificacion;
END
GO

EXEC dbo.sp_contrato_historial_por_cliente @identificacion = 12345678;

