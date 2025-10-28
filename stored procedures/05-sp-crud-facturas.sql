USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE dbo.sp_insertFactura
  @idContrato         INT,
  @porcentajeIVA      DECIMAL(5,2) = 13.00,
  @idFactura          INT OUTPUT
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE 
      @montoPagado DECIMAL(18,2),
      @porcentajeComision DECIMAL(5,2),
      @montoComision DECIMAL(18,2),
      @iva DECIMAL(18,2),
      @idPropiedad INT,
      @idTipoContrato INT,
      @idAgente INT,
      @deposito DECIMAL(18,2),
      @nombreTipoContrato VARCHAR(20);

    --  Validar existencia del contrato y traer datos relevantes
    SELECT 
      @montoPagado = montoTotal,
      @porcentajeComision = porcentajeComision,
      @idPropiedad = idPropiedad,
      @idTipoContrato = idTipoContrato,
      @idAgente = idAgente,
      @deposito = deposito
    FROM Contrato
    WHERE idContrato = @idContrato;

    IF NOT EXISTS (SELECT 1 FROM Contrato WHERE idContrato = @idContrato)
    THROW 50009, 'El contrato indicado no existe.', 1;

    IF @montoPagado IS NULL OR @montoPagado <= 0
      THROW 50010, 'El contrato no tiene un monto total válido.', 1;

    IF @porcentajeComision IS NULL OR @porcentajeComision < 0 OR @porcentajeComision > 100
      THROW 50011, 'El contrato no tiene un porcentaje de comisión válido.', 1;

    IF @porcentajeIVA IS NULL OR @porcentajeIVA < 0 OR @porcentajeIVA > 100
      THROW 50012, 'El porcentaje de IVA debe estar entre 0 y 100.', 1;

    IF @idPropiedad IS NULL OR @idTipoContrato IS NULL
      THROW 50013, 'El contrato no tiene propiedad o tipo de contrato asignado.', 1;

    IF @idAgente IS NULL
    THROW 50014, 'El contrato no tiene un agente asignado.',1;

    --  Validar agente
    IF NOT EXISTS (SELECT 1 FROM Agente WHERE identificacion = @idAgente)
      THROW 50014, 'El agente no existe.', 1;

      -- Validar que el contrato tenga clientes asociados
    IF NOT EXISTS (
    SELECT 1 FROM ClienteContrato WHERE idContrato = @idContrato
     )
    THROW 50015, 'El contrato no tiene clientes asociados. No se puede emitir una factura.', 1;

    -- Obtener el nombre del tipo de contrato
    SELECT @nombreTipoContrato = nombre FROM TipoContrato WHERE idTipoContrato = @idTipoContrato;

    --Valida que si es de venta, solo se le pueda hacer una factura.
    IF @nombreTipoContrato = 'Venta' 
       AND EXISTS (SELECT 1 FROM Factura WHERE idContrato = @idContrato)
      THROW 50017, 'No se pueden crear múltiples facturas para contratos de tipo Venta.', 1;

      -- Si el contrato es de alquiler vemos que no haya sido pagado completamente.
    IF @deposito IS NOT NULL AND @deposito > 0
    BEGIN
      DECLARE @totalPagado DECIMAL(18,2);
      SELECT @totalPagado = ISNULL(SUM(montoPagado), 0)
      FROM Factura
      WHERE idContrato = @idContrato AND estadoPago = 1;

      IF @totalPagado >= @montoPagado
        THROW 50018, 'El contrato de alquiler ya ha sido pagado completamente. No se pueden emitir más facturas.', 1;
    END;

    --  Cálculos
    SET @iva = ROUND(@montoPagado * (@porcentajeIVA / 100.0), 2);
    SET @montoComision = ROUND(@montoPagado * (@porcentajeComision / 100.0), 2);

    --  Insertar factura
    INSERT INTO Factura (
        montoPagado, 
        fechaEmision, 
        fechaPago,
        estadoPago, 
        iva, 
        idContrato, 
        idAgente, 
        idPropiedad,
        idTipoContrato,
        montoComision, 
        porcentajeComision
    )
    VALUES (
        @montoPagado, 
        DEFAULT,          
        NULL,              
        0,                 
        @iva, 
        @idContrato, 
        @idAgente, 
        @idPropiedad,
        @idTipoContrato,
        @montoComision, 
        @porcentajeComision
    );

    -- Guardar idFactura generado
    SET @idFactura = SCOPE_IDENTITY();


    COMMIT TRANSACTION;

    --  Respuesta del SP
    SELECT 
        @idFactura AS idFactura,
        @idContrato AS idContrato,
        @idAgente AS idAgente,
        @montoPagado AS montoPagado,
        @porcentajeComision AS porcentajeComision,
        @montoComision AS montoComision,
        @iva AS iva,
        @porcentajeIVA AS porcentajeIVA,
        'Factura creada correctamente' AS mensaje;

  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    THROW 50099, @msg, 1;
  END CATCH;
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
        CONCAT(a.nombre, ' ', a.apellido1, ' ', a.identificacion) AS nombreAgente,
        f.porcentajeComision,
        CONVERT(varchar(10), f.fechaEmision, 23) AS fechaEmision,
        CONVERT(varchar(10), f.fechaPago, 23) AS fechaPago,
        f.estadoPago,
        c.idContrato,

        -- Solo mostrar al cliente con rol relevante según el tipo de contrato
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
    INNER JOIN Contrato      c  ON c.idContrato   = f.idContrato
    INNER JOIN Propiedad     p  ON p.idPropiedad  = c.idPropiedad
    INNER JOIN TipoContrato  tc ON tc.idTipoContrato = c.idTipoContrato
    INNER JOIN Agente        a  ON a.identificacion = f.idAgente
    ORDER BY f.idFactura DESC;
END;
GO


--SP READ
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_getFacturasFiltradas
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
        CONCAT(a.nombre, ' ', a.apellido1) AS nombreAgente,
        f.porcentajeComision,
        FORMAT(f.fechaEmision, 'yyyy-MM-dd') AS fechaEmision,
        FORMAT(f.fechaPago, 'yyyy-MM-dd') AS fechaPago,
        f.estadoPago,
        c.idContrato,
        STRING_AGG(CONCAT(cl.identificacion, ' - ', cl.nombre, ' ', cl.apellido1, ' (', tr.nombre, ')'), ', ') AS clientes,
        f.montoPagado
    FROM Factura f
    INNER JOIN Contrato c ON f.idContrato = c.idContrato
    INNER JOIN Propiedad p ON c.idPropiedad = p.idPropiedad
    INNER JOIN TipoContrato tc ON c.idTipoContrato = tc.idTipoContrato
    INNER JOIN Agente a ON f.idAgente = a.identificacion
    INNER JOIN FacturaCliente fc ON f.idFactura = fc.idFactura
    INNER JOIN Cliente cl ON fc.identificacion = cl.identificacion
    LEFT JOIN ClienteContrato cc ON cc.idContrato = c.idContrato AND cc.identificacion = cl.identificacion
    LEFT JOIN TipoRol tr ON tr.idRol = cc.idRol
    WHERE
        (@estadoPago IS NULL OR f.estadoPago = @estadoPago)
        AND (@idContrato IS NULL OR c.idContrato = @idContrato)
        AND (@idCliente IS NULL OR cl.identificacion = @idCliente)
        AND (@fecha IS NULL OR CAST(f.fechaEmision AS DATE) = @fecha)
    GROUP BY 
        f.idFactura, tc.nombre, p.idPropiedad, a.nombre, a.apellido1,
        f.porcentajeComision, f.fechaEmision, f.fechaPago,
        f.estadoPago, c.idContrato, f.montoPagado
    ORDER BY f.idFactura DESC;
END;
GO



-- SP_UPDATEESTADO
USE AltosDelValle;
GO

CREATE OR ALTER PROCEDURE sp_updateFacturaEstado
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
      @deposito DECIMAL(18,2),
      @montoFactura DECIMAL(18,2),
      @montoTotalContrato DECIMAL(18,2),
      @porcentajeComision DECIMAL(5,2),
      @montoComision DECIMAL(18,2),
      @facturasPagadas INT;

    SELECT 
      @idContrato = idContrato,
      @idAgente = idAgente,
      @montoFactura = montoPagado,
      @porcentajeComision = porcentajeComision
    FROM Factura 
    WHERE idFactura = @idFactura;

    IF @idContrato IS NULL
      THROW 50010, 'La factura no existe o no tiene contrato asociado.', 1;


    SELECT 
      @idTipoContrato = idTipoContrato,
      @deposito = deposito,
      @montoTotalContrato = montoTotal
    FROM Contrato 
    WHERE idContrato = @idContrato;

    IF EXISTS (SELECT 1 FROM Factura WHERE idFactura = @idFactura AND estadoPago = 1)
      THROW 50011, 'Esta factura ya fue pagada.', 1;

    UPDATE Factura
    SET estadoPago = 1,
        fechaPago = GETDATE()
    WHERE idFactura = @idFactura;

    SELECT @facturasPagadas = COUNT(*) 
    FROM Factura 
    WHERE idContrato = @idContrato AND estadoPago = 1;

  
    IF @idTipoContrato = 1  -- Contrato de Venta
    BEGIN
        -- Calcular comisión
        SET @montoComision = ROUND(@montoFactura * (@porcentajeComision / 100.0), 2);

        -- Insertar registro en Comision
        INSERT INTO Comision (idAgente, idFactura, idContrato, montoComision, porcentajeComision)
        VALUES (@idAgente, @idFactura, @idContrato, @montoComision, @porcentajeComision);

        -- Acreditar comisión al agente
        UPDATE Agente
        SET comisionAcumulada = comisionAcumulada + @montoComision
        WHERE identificacion = @idAgente;

        -- Finalizar contrato
        UPDATE Contrato 
        SET estado = 'Finalizado' 
        WHERE idContrato = @idContrato;
    END
    ELSE  -- 
    BEGIN
        -- Si es la primera factura pagada, activar contrato y generar comisión
        IF @facturasPagadas = 1
        BEGIN
            UPDATE Contrato 
            SET estado = 'Activo' 
            WHERE idContrato = @idContrato;

            SET @montoComision = ROUND(@montoFactura * (@porcentajeComision / 100.0), 2);

            INSERT INTO Comision (idAgente, idFactura, idContrato, montoComision, porcentajeComision)
            VALUES (@idAgente, @idFactura, @idContrato, @montoComision, @porcentajeComision);

            UPDATE Agente
            SET comisionAcumulada = comisionAcumulada + @montoComision
            WHERE identificacion = @idAgente;
        END

        -- Si el total pagado ya cubre todo el contrato, finalizarlo
        DECLARE @totalPagado DECIMAL(18,2);
        SELECT @totalPagado = ISNULL(SUM(montoPagado), 0)
        FROM Factura 
        WHERE idContrato = @idContrato AND estadoPago = 1;

        IF @deposito IS NULL OR @deposito = 0
        BEGIN
           IF @totalPagado >= @montoTotalContrato
               UPDATE Contrato SET estado = 'Finalizado' WHERE idContrato = @idContrato;
        END
        ELSE
        BEGIN
         UPDATE Contrato SET estado = 'Activo' WHERE idContrato = @idContrato;
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
        'Factura actualizada correctamente' AS mensaje
    FROM Factura f
    INNER JOIN Contrato c ON f.idContrato = c.idContrato
    WHERE f.idFactura = @idFactura;

  END TRY
  BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
    THROW 50099, @msg, 1;
  END CATCH;
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
      THROW 50011, 'Uno o más clientes no pertenecen al contrato asociado a la factura.', 1;


    -- Validar que los clientes no hayan sido agregados ya a esa factura.
    IF EXISTS(
        SELECT 1
        FROM @data d
        INNER JOIN FacturaCliente fc
        ON fc.idFactura = d.idFactura AND fc.identificacion = d.identificacion
    )
    THROW 50017, 'Uno o más clientes ya están asociados a esta factura', 1;

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
