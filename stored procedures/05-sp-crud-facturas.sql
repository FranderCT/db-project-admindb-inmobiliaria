USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertFactura
  @idContrato     INT,
  @porcentajeIva  DECIMAL(5,2) = 13.00,
  @idFactura      INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE 
      @montoTotalContrato   DECIMAL(18,2),
      @montoFactura         DECIMAL(18,2),
      @porcentajeComision   DECIMAL(5,2),
      @montoComision        DECIMAL(18,2),
      @iva                  DECIMAL(18,2),
      @idPropiedad          INT,
      @idTipoContrato       INT,
      @idAgente             INT,
      @nombreTipoContrato   VARCHAR(20),
      @cantidadPagos        INT,
      @facturasEmitidas     INT,
      @totalEmitido         DECIMAL(18,2),
      @fechaPagoContrato    DATETIME,
      @idEstadoVendida      INT,
      @idEstadoReservada    INT;

    /* ===== Obtener IDs de estado de propiedad ===== */
    SELECT @idEstadoVendida = idEstadoPropiedad FROM EstadoPropiedad WHERE nombre = 'Vendida';
    SELECT @idEstadoReservada = idEstadoPropiedad FROM EstadoPropiedad WHERE nombre = 'Reservada';

    IF @idEstadoVendida IS NULL OR @idEstadoReservada IS NULL
      THROW 50008, 'No se encontraron los estados de propiedad requeridos (Vendida / Reservada).', 1;

    /* ===== Validaciones base y lectura de contrato ===== */
    IF NOT EXISTS (SELECT 1 FROM Contrato WHERE idContrato = @idContrato)
      THROW 50009, 'El contrato indicado no existe.', 1;

    SELECT 
      @montoTotalContrato  = CAST(montoTotal AS DECIMAL(18,2)),
      @porcentajeComision  = porcentajeComision,
      @idPropiedad         = idPropiedad,
      @idTipoContrato      = idTipoContrato,
      @idAgente            = idAgente,
      @cantidadPagos       = cantidadPagos,
      @fechaPagoContrato   = fechaPago
    FROM Contrato
    WHERE idContrato = @idContrato;

    IF @montoTotalContrato IS NULL OR @montoTotalContrato <= 0
      THROW 50010, 'El contrato no tiene un monto total válido.', 1;

    IF @porcentajeComision IS NULL OR @porcentajeComision < 0 OR @porcentajeComision > 100
      THROW 50011, 'El contrato no tiene un porcentaje de comisión válido.', 1;

    IF @porcentajeIva IS NULL OR @porcentajeIva < 0 OR @porcentajeIva > 100
      THROW 50012, 'El porcentaje de IVA debe estar entre 0 y 100.', 1;

    IF @idPropiedad IS NULL OR @idTipoContrato IS NULL
      THROW 50013, 'El contrato no tiene propiedad o tipo de contrato asignado.', 1;

    IF @idAgente IS NULL
      THROW 50014, 'El contrato no tiene un agente asignado.', 1;

    IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @idAgente)
      THROW 50014, 'El agente no existe.', 1;

    IF NOT EXISTS (SELECT 1 FROM ClienteContrato WHERE idContrato = @idContrato)
      THROW 50015, 'El contrato no tiene clientes asociados. No se puede emitir una factura.', 1;

    SELECT @nombreTipoContrato = nombre
    FROM TipoContrato
    WHERE idTipoContrato = @idTipoContrato;

    /* ===== Reglas por tipo de contrato ===== */
    IF @nombreTipoContrato = 'Venta'
    BEGIN
      IF EXISTS (SELECT 1 FROM Factura WHERE idContrato = @idContrato)
        THROW 50017, 'No se pueden crear múltiples facturas para contratos de tipo Venta.', 1;

      SET @montoFactura = @montoTotalContrato;

      -- Actualizar contrato como Finalizado al crear factura
      UPDATE Contrato
      SET estado = 'Finalizado', fechaPago = GETDATE()
      WHERE idContrato = @idContrato;

      -- Marcar propiedad como Vendida (usando idEstado)
      UPDATE Propiedad
      SET idEstado = @idEstadoVendida
      WHERE idPropiedad = @idPropiedad;
    END
    ELSE IF @nombreTipoContrato = 'Alquiler'
    BEGIN
      IF @cantidadPagos IS NULL OR @cantidadPagos <= 0
        THROW 50019, 'El contrato de alquiler no tiene una cantidad de pagos válida.', 1;

      IF @fechaPagoContrato IS NOT NULL AND CONVERT(date, GETDATE()) < CONVERT(date, @fechaPagoContrato)
        THROW 50025, 'No puede crear una factura antes de la fecha de pago establecida en el contrato.', 1;

      SELECT 
        @facturasEmitidas = COUNT(*),
        @totalEmitido     = ISNULL(SUM(CAST(montoPagado AS DECIMAL(18,2))), 0)
      FROM Factura
      WHERE idContrato = @idContrato;

      IF @facturasEmitidas >= @cantidadPagos
        THROW 50020, 'Ya se han generado todas las facturas correspondientes a este contrato de alquiler.', 1;

      DECLARE @cuota DECIMAL(18,2) = ROUND(@montoTotalContrato / @cantidadPagos, 2);

      IF @facturasEmitidas = (@cantidadPagos - 1)
        SET @montoFactura = @montoTotalContrato - @totalEmitido;
      ELSE
        SET @montoFactura = @cuota;

      IF @montoFactura <= 0
        THROW 50021, 'El monto calculado para la factura de alquiler no es válido.', 1;

      -- Si es la primera factura => activar contrato
      IF @facturasEmitidas = 0
      BEGIN
        UPDATE Contrato
        SET estado = 'Activo'
        WHERE idContrato = @idContrato;
      END

      -- Marcar propiedad como Reservada
      UPDATE Propiedad
      SET idEstado = @idEstadoReservada
      WHERE idPropiedad = @idPropiedad;
    END
    ELSE
      THROW 50022, 'Tipo de contrato desconocido.', 1;

    /* ===== Cálculos de IVA y comisión ===== */
    SET @iva = ROUND(@montoFactura * (@porcentajeIva / 100.0), 2);
    SET @montoComision = ROUND(@montoFactura * (@porcentajeComision / 100.0), 2);

    /* ===== Insert de factura ===== */
    INSERT INTO Factura (
        montoPagado, fechaEmision, fechaPago, estadoPago,
        iva, porcentajeIva, idContrato, idAgente,
        idPropiedad, idTipoContrato, montoComision, porcentajeComision
    )
    VALUES (
        @montoFactura, DEFAULT, NULL, 0,
        @iva, @porcentajeIva, @idContrato, @idAgente,
        @idPropiedad, @idTipoContrato, @montoComision, @porcentajeComision
    );

    SET @idFactura = SCOPE_IDENTITY();

    /* ===== Asociar automáticamente los clientes del contrato ===== */
    INSERT INTO FacturaCliente (idFactura, identificacion)
    SELECT @idFactura, cc.identificacion
    FROM ClienteContrato cc
    WHERE cc.idContrato = @idContrato
      AND NOT EXISTS (
          SELECT 1 FROM FacturaCliente fc
          WHERE fc.idFactura = @idFactura AND fc.identificacion = cc.identificacion
      );

    COMMIT TRANSACTION;

    SELECT 
      @idFactura AS idFactura,
      @idContrato AS idContrato,
      @idAgente AS idAgente,
      @nombreTipoContrato AS tipoContrato,
      @montoFactura AS montoFactura,
      @cantidadPagos AS cantidadPagos,
      @porcentajeComision AS porcentajeComision,
      @montoComision AS montoComision,
      @iva AS iva,
      @porcentajeIva AS porcentajeIva,
      'Factura creada correctamente' AS mensaje;

  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    THROW 50099, @msg, 1;
  END CATCH
END;
GO




-- SP_READ
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_getFacturas
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        f.idFactura,
        tc.nombre AS tipoContrato,
        p.idPropiedad,
        p.ubicacion,
        CONCAT(a.nombre, ' ', a.apellido1) AS nombreAgente,
        f.porcentajeComision,
        CONVERT(varchar(10), f.fechaEmision, 23) AS fechaEmision,
        CONVERT(varchar(10), f.fechaPago, 23) AS fechaPago,
        f.estadoPago,
        c.idContrato,
        f.porcentajeIva,
        ISNULL(
            (
                SELECT TOP 1
                    CONCAT(
                        cl.identificacion, ' - ', cl.nombre, ' ', cl.apellido1,
                        ' (', ISNULL(tr.nombre, 'Sin rol'), ')'
                    )
                FROM FacturaCliente fc
                INNER JOIN Cliente cl ON cl.identificacion = fc.identificacion
                INNER JOIN ClienteContrato cc ON cc.idContrato = c.idContrato
                                              AND cc.identificacion = cl.identificacion
                INNER JOIN TipoRol tr ON tr.idRol = cc.idRol
                WHERE fc.idFactura = f.idFactura
                  AND (
                        (tc.nombre = 'Venta' AND tr.nombre = 'Comprador')
                     OR (tc.nombre = 'Alquiler' AND tr.nombre = 'Inquilino')
                  )
            ),
            'No asignado'
        ) AS clientePrincipal,
        f.montoPagado
    FROM Factura f
    INNER JOIN Contrato c ON c.idContrato = f.idContrato
    INNER JOIN Propiedad p ON p.idPropiedad = c.idPropiedad
    INNER JOIN TipoContrato tc ON tc.idTipoContrato = c.idTipoContrato
    INNER JOIN Agente a ON a.identificacion = f.idAgente
    ORDER BY f.idFactura DESC;
END;
GO



--SP READ
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_getFacturasFiltradas
    @estadoPago BIT = NULL,         
    @idContrato INT = NULL,
    @idCliente BIGINT = NULL,
    @fecha DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        f.idFactura,
        tc.nombre AS tipoContrato,
        p.idPropiedad,
        p.ubicacion,
        CONCAT(a.nombre, ' ', a.apellido1) AS nombreAgente,
        f.porcentajeComision,
        CONVERT(varchar(10), f.fechaEmision, 23) AS fechaEmision,
        CONVERT(varchar(10), f.fechaPago, 23) AS fechaPago,
        f.estadoPago,
        c.idContrato,
        f.porcentajeIva,
        ISNULL(
            (
                SELECT TOP 1
                    CONCAT(
                        cl.identificacion, ' - ', cl.nombre, ' ', cl.apellido1,
                        ' (', ISNULL(tr.nombre, 'Sin rol'), ')'
                    )
                FROM FacturaCliente fc2
                INNER JOIN Cliente cl ON cl.identificacion = fc2.identificacion
                INNER JOIN ClienteContrato cc ON cc.idContrato = c.idContrato
                                              AND cc.identificacion = cl.identificacion
                INNER JOIN TipoRol tr ON tr.idRol = cc.idRol
                WHERE fc2.idFactura = f.idFactura
                  AND (
                        (tc.nombre = 'Venta' AND tr.nombre = 'Comprador')
                     OR (tc.nombre = 'Alquiler' AND tr.nombre = 'Inquilino')
                  )
            ),
            'No asignado'
        ) AS cliente,
        f.montoPagado
    FROM Factura f
    INNER JOIN Contrato c ON f.idContrato = c.idContrato
    INNER JOIN Propiedad p ON p.idPropiedad = c.idPropiedad
    INNER JOIN TipoContrato tc ON tc.idTipoContrato = c.idTipoContrato
    INNER JOIN Agente a ON a.identificacion = f.idAgente
    LEFT JOIN FacturaCliente fc ON fc.idFactura = f.idFactura
    LEFT JOIN Cliente cl ON fc.identificacion = cl.identificacion
    LEFT JOIN ClienteContrato cc ON cc.idContrato = c.idContrato AND cc.identificacion = cl.identificacion
    LEFT JOIN TipoRol tr ON tr.idRol = cc.idRol
    WHERE
        (@estadoPago IS NULL OR f.estadoPago = @estadoPago)
        AND (@idContrato IS NULL OR c.idContrato = @idContrato)
        AND (@fecha IS NULL OR CAST(f.fechaEmision AS DATE) = @fecha)
        AND (
            @idCliente IS NULL
            OR (
                cl.identificacion = @idCliente
                AND (
                    (tc.nombre = 'Venta' AND tr.nombre = 'Comprador')
                    OR (tc.nombre = 'Alquiler' AND tr.nombre = 'Inquilino')
                )
            )
        )
    GROUP BY 
        f.idFactura, tc.nombre, p.idPropiedad, p.ubicacion, a.nombre, a.apellido1,
        f.porcentajeComision, f.fechaEmision, f.fechaPago,
        f.estadoPago, c.idContrato, f.montoPagado, f.porcentajeIva
    ORDER BY f.idFactura DESC;
END;
GO






-- SP_UPDATEESTADO
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_updateFacturaEstado
  @idFactura INT
AS
BEGIN
  SET NOCOUNT ON;

  BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE 
      @idContrato INT,
      @idAgente INT,
      @idTipoContrato INT,
      @idPropiedad INT,
      @montoFactura DECIMAL(18,2),
      @montoTotalContrato DECIMAL(18,2),
      @porcentajeComision DECIMAL(5,2),
      @montoComision DECIMAL(18,2),
      @facturasPagadas INT,
      @fechaPagoActual DATETIME,
      @totalPagado DECIMAL(18,2),
      @idEstadoVendida INT,
      @idEstadoDisponible INT;

    /* ===== Obtener IDs de estado de propiedad ===== */
    SELECT @idEstadoVendida = idEstadoPropiedad FROM EstadoPropiedad WHERE nombre = 'Vendida';
    SELECT @idEstadoDisponible = idEstadoPropiedad FROM EstadoPropiedad WHERE nombre = 'Disponible';

    IF @idEstadoVendida IS NULL OR @idEstadoDisponible IS NULL
      THROW 50008, 'No se encontraron los estados de propiedad requeridos (Vendida / Disponible).', 1;

    /* ===== Datos de la factura ===== */
    SELECT 
      @idContrato = f.idContrato,
      @idAgente = f.idAgente,
      @montoFactura = CAST(f.montoPagado AS DECIMAL(18,2)),
      @porcentajeComision = f.porcentajeComision
    FROM Factura f
    WHERE f.idFactura = @idFactura;

    IF @idContrato IS NULL
      THROW 50010, 'La factura no existe o no tiene contrato asociado.', 1;

    IF EXISTS (SELECT 1 FROM Factura WHERE idFactura = @idFactura AND estadoPago = 1)
      THROW 50011, 'Esta factura ya fue pagada.', 1;

    SELECT 
      @idTipoContrato = c.idTipoContrato,
      @montoTotalContrato = CAST(c.montoTotal AS DECIMAL(18,2)),
      @idPropiedad = c.idPropiedad
    FROM Contrato c
    WHERE c.idContrato = @idContrato;

    SET @fechaPagoActual = GETDATE();

    UPDATE Factura
    SET estadoPago = 1,
        fechaPago = @fechaPagoActual
    WHERE idFactura = @idFactura;

    SET @montoComision = ROUND(@montoFactura * (@porcentajeComision / 100.0), 2);

    INSERT INTO Comision (idAgente, idFactura, idContrato, montoComision, porcentajeComision)
    VALUES (@idAgente, @idFactura, @idContrato, @montoComision, @porcentajeComision);

    UPDATE Agente
    SET comisionAcumulada = comisionAcumulada + @montoComision
    WHERE identificacion = @idAgente;

    SELECT @facturasPagadas = COUNT(*)
    FROM Factura
    WHERE idContrato = @idContrato AND estadoPago = 1;

    IF @idTipoContrato = 1  -- VENTA
    BEGIN
      UPDATE Contrato
      SET estado = 'Finalizado', fechaPago = @fechaPagoActual
      WHERE idContrato = @idContrato;

      UPDATE Propiedad
      SET idEstado = @idEstadoVendida
      WHERE idPropiedad = @idPropiedad;
    END
    ELSE  -- ALQUILER
    BEGIN
      IF @facturasPagadas = 1
      BEGIN
        UPDATE Contrato
        SET estado = 'Activo'
        WHERE idContrato = @idContrato;
      END

      SELECT @totalPagado = ISNULL(SUM(CAST(montoPagado AS DECIMAL(18,2))), 0)
      FROM Factura
      WHERE idContrato = @idContrato AND estadoPago = 1;

      IF @totalPagado >= @montoTotalContrato
      BEGIN
        UPDATE Contrato
        SET estado = 'Finalizado', fechaPago = @fechaPagoActual
        WHERE idContrato = @idContrato;

        UPDATE Propiedad
        SET idEstado = @idEstadoDisponible
        WHERE idPropiedad = @idPropiedad;
      END
    END

    COMMIT TRANSACTION;

    SELECT 
      f.idFactura,
      f.idContrato,
      f.idAgente,
      f.montoPagado,
      f.fechaEmision,
      f.fechaPago,
      f.estadoPago,
      c.estado AS estadoContrato,
      c.fechaPago AS fechaPagoContrato,
      ep.nombre AS estadoPropiedad,
      'Factura actualizada correctamente' AS mensaje
    FROM Factura f
    INNER JOIN Contrato c ON f.idContrato = c.idContrato
    INNER JOIN Propiedad p ON p.idPropiedad = c.idPropiedad
    INNER JOIN EstadoPropiedad ep ON p.idEstado = ep.idEstadoPropiedad
    WHERE f.idFactura = @idFactura;

  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    THROW 50099, @msg, 1;
  END CATCH
END;
GO




-- TABLA INTERMEDIA FACTURA - CLIENTE 

-- INSERT

USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_insertFacturaCliente
  @identificacion INT,
  @idFactura INT
AS
BEGIN
  SET NOCOUNT ON;

  DECLARE @idContrato INT;

  -- Validar existencia de factura
  SELECT @idContrato = idContrato FROM Factura WHERE idFactura = @idFactura;
  IF @idContrato IS NULL
    THROW 50010, 'La factura no existe.', 1;

  -- Validar que el cliente pertenezca al contrato de esa factura
  IF NOT EXISTS (
    SELECT 1
    FROM ClienteContrato
    WHERE identificacion = @identificacion
      AND idContrato = @idContrato
  )
    THROW 50011, 'El cliente no pertenece al contrato asociado a esta factura.', 1;


    --Validar que el cliente no se haya asociado ya a esa factura.
    IF EXISTS(
        SELECT 1
        FROM FacturaCliente
        WHERE identificacion = @identificacion
        AND idFactura = @idFactura
    )
    THROW 50017, 'El cliente ya ha sido asociado a esta factura', 1;

  -- Insertar en FacturaCliente
  INSERT INTO FacturaCliente (identificacion, idFactura)
  VALUES (@identificacion, @idFactura);

  -- Devolver el registro insertado con detalles
  SELECT 
    fc.idFacturaCliente,
    fc.idFactura,
    c.identificacion,
    c.nombre AS nombreCliente
  FROM FacturaCliente fc
  INNER JOIN Cliente c ON fc.identificacion = c.identificacion
  WHERE fc.idFacturaCliente = SCOPE_IDENTITY();
END;
GO


--INSERT DE FACTURA CON VARIOS CLIENTES.

USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_insertFacturaClienteVarios
  @json NVARCHAR(MAX)
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @data TABLE (
      identificacion INT,
      idFactura INT
    );

    INSERT INTO @data (identificacion, idFactura)
    SELECT identificacion, idFactura
    FROM OPENJSON(@json)
    WITH (
      identificacion INT,
      idFactura INT
    );

    DECLARE @idFactura INT, @idContrato INT;
    SELECT TOP 1 @idFactura = idFactura FROM @data;
    SELECT @idContrato = idContrato FROM Factura WHERE idFactura = @idFactura;

    IF @idContrato IS NULL
      THROW 50010, 'La factura no existe o no tiene contrato asociado.', 1;

    -- Validar que todos los clientes pertenezcan al contrato
    IF EXISTS (
      SELECT d.identificacion
      FROM @data d
      WHERE d.identificacion NOT IN (
        SELECT cc.identificacion FROM ClienteContrato cc WHERE cc.idContrato = @idContrato
      )
    )
      THROW 50011, 'Uno o m s clientes no pertenecen al contrato asociado a la factura.', 1;


    -- Validar que los clientes no hayan sido agregados ya a esa factura.
    IF EXISTS(
        SELECT 1
        FROM @data d
        INNER JOIN FacturaCliente fc
        ON fc.idFactura = d.idFactura AND fc.identificacion = d.identificacion
    )
    THROW 50017, 'Uno o m s clientes ya est n asociados a esta factura', 1;

    -- Insertar en FacturaCliente
    INSERT INTO FacturaCliente (identificacion, idFactura)
    SELECT identificacion, idFactura FROM @data;

    -- Devolver registros insertados
    SELECT 
      fc.idFacturaCliente,
      fc.idFactura,
      c.identificacion,
      c.nombre AS nombreCliente
    FROM FacturaCliente fc
    INNER JOIN Cliente c ON fc.identificacion = c.identificacion
    WHERE fc.idFactura IN (SELECT DISTINCT idFactura FROM @data);

    COMMIT TRANSACTION;
  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    THROW 50099, @msg, 1;
  END CATCH;
END;
GO




--COMISIONES

-- SP_READ

USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_getComisiones
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 
    c.idComision,
    c.idFactura,
    c.idContrato,
    a.identificacion AS idAgente,
    a.nombre AS nombreAgente,
    c.montoComision,
    c.porcentajeComision,
    c.fechaComision,
    c.estado,
    c.mes,
    c.anio,
    f.montoPagado,
    f.estadoPago
  FROM Comision c
  INNER JOIN Agente a ON c.idAgente = a.identificacion
  INNER JOIN Factura f ON c.idFactura = f.idFactura
  ORDER BY c.fechaComision DESC;
END;
GO