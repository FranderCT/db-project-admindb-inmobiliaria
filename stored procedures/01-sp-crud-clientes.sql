-- SP_INSERT 
USE AltosDelValle;
GO

-- TABLA CLIENTES
use AltosDelValle
GO
CREATE OR ALTER PROCEDURE dbo.sp_insertCliente
    @identificacion INT,
    @nombre         VARCHAR(30),
    @apellido1      VARCHAR(30),
    @apellido2      VARCHAR(30) = NULL,
    @telefono       int
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE identificacion = @identificacion)
        THROW 50010, 'La identificación ya está registrada.', 1;
        
        IF @identificacion IS NULL OR @identificacion <= 0
        THROW 50011, 'La identificación es obligatoria y debe ser > 0.', 1;

        IF @nombre IS NULL OR LTRIM(RTRIM(@nombre)) = ''
        THROW 50012, 'El nombre es obligatorio.', 1;

        IF @apellido1 IS NULL OR LTRIM(RTRIM(@apellido1)) = ''
        THROW 50013, 'El primer apellido es obligatorio.', 1;

        IF @telefono IS NULL OR LTRIM(RTRIM(@telefono)) = ''
        THROW 50014, 'El teléfono es obligatorio.', 1;

        IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE telefono = @telefono)
        THROW 50015, 'El teléfono ya está registrado.', 1;

        INSERT INTO dbo.Cliente (identificacion, nombre, apellido1, apellido2, telefono)
        VALUES (@identificacion, @nombre, @apellido1, @apellido2, @telefono);

        SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
        FROM dbo.Cliente
        WHERE identificacion = @identificacion;
    END TRY
    BEGIN CATCH
        DECLARE @num INT = ERROR_NUMBER(),
                @msg NVARCHAR(4000) = ERROR_MESSAGE();

        
        IF @num BETWEEN 50010 AND 50099
        THROW @num, @msg, 1;

        
        DECLARE @fullMsg NVARCHAR(4000) = N'Error al insertar cliente: ' + @msg;
        THROW 50050, @fullMsg, 1;
    END CATCH
END
GO

-- sp leer todos los clientes 
use AltosDelValle
GO
CREATE OR ALTER PROCEDURE dbo.sp_clienteLeerTodos
AS
BEGIN
    SET NOCOUNT ON; 
    -- validar que no esta vacio la tabla
    IF NOT EXISTS (SELECT 1 FROM dbo.Cliente)
        THROW 50020, 'No hay clientes registrados.', 1;
    SELECT identificacion, nombre, apellido1, apellido2, telefono, estado
    FROM dbo.Cliente;
END
GO

-- sp para actualizar cliente
use AltosDelValle
GO
CREATE OR ALTER PROCEDURE dbo.sp_updateCliente
  @identificacion INT,
  @nombre         VARCHAR(30) = NULL,
  @apellido1      VARCHAR(30) = NULL,
  @apellido2      VARCHAR(30) = NULL,
  @telefono       int = NULL,
  @estado         BIT = NULL
AS
BEGIN
  SET NOCOUNT ON;
  
  IF @identificacion IS NULL OR @identificacion <= 0
      THROW 50020, 'La identificación es obligatoria y debe ser > 0.', 1;

  IF NOT EXISTS (SELECT 1 FROM dbo.Cliente WHERE identificacion = @identificacion)
      THROW 50030, 'Cliente no encontrado.', 1;

  IF EXISTS (SELECT 1 FROM dbo.Cliente WHERE telefono = @telefono AND identificacion <> @identificacion)
      THROW 50040, 'El teléfono ya está registrado por otro cliente.', 1;

  -- Actualizar los campos que no son nulos
  UPDATE dbo.Cliente
  SET
    nombre = COALESCE(@nombre, nombre),
    apellido1 = COALESCE(@apellido1, apellido1),
    apellido2 = COALESCE(@apellido2, apellido2),
    telefono = COALESCE(@telefono, telefono),
    estado = COALESCE(@estado, estado)
  WHERE identificacion = @identificacion;

  select identificacion, nombre, apellido1, apellido2, telefono, estado
  from dbo.Cliente
  where identificacion = @identificacion;

END
GO

-- sp para ver el historial de contratos en los que ha participado un cliente
use AltosDelValle
GO
CREATE OR ALTER PROCEDURE  dbo.sp_contratoHistorialPorCliente
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

use AltosDelValle
GO
create or alter PROCEDURE sp_clientePorIdentificacion
  @identificacion INT
AS
BEGIN

  IF NOT EXISTS (
    SELECT 1
    FROM Cliente
    WHERE identificacion = @identificacion
  )
  BEGIN
    RAISERROR('Cliente no encontrado.', 16, 1);
    RETURN;
  END

  SELECT 
    identificacion,
    nombre,
    apellido1,
    apellido2,
    telefono,
    estado
  FROM Cliente
  WHERE identificacion = @identificacion;
END
GO

---TABLA INTERMEDIA ClienteContrato
---sp_clienteContrato_insertar
use AltosDelValle
GO
CREATE or alter PROCEDURE sp_insertClientesContrato
  @identificacion INT,
  @idRol INT,
  @idContrato INT
AS
BEGIN
  INSERT INTO ClienteContrato (identificacion, idRol, idContrato)
  VALUES (@identificacion, @idRol, @idContrato);

  -- Retorna el registro insertado
  SELECT 
    cc.idClienteContrato,
    cc.idContrato,
    c.identificacion,
    c.nombre AS nombreCliente,
    tr.nombre AS rol
  FROM ClienteContrato cc
  INNER JOIN Cliente c ON cc.identificacion = c.identificacion
  INNER JOIN TipoRol tr ON cc.idRol = tr.idRol
  WHERE cc.idClienteContrato = SCOPE_IDENTITY();
END
GO

--sp_clienteContrato_insertar_varios  
--Este inserta varios clientes en un contrato  
use AltosDelValle
GO
CREATE or alter PROCEDURE  sp_clienteContratoInsertarVarios
  @json NVARCHAR(MAX)
AS
BEGIN
  -- Convertir JSON a tabla
  DECLARE @data TABLE (
    identificacion INT,
    idRol INT,
    idContrato INT
  );

  INSERT INTO @data (identificacion, idRol, idContrato)
  SELECT identificacion, idRol, idContrato
  FROM OPENJSON(@json)
  WITH (
    identificacion INT,
    idRol INT,
    idContrato INT
  );

  -- Insertar en tabla real
  INSERT INTO ClienteContrato (identificacion, idRol, idContrato)
  SELECT identificacion, idRol, idContrato FROM @data;

  -- Retornar lo insertado si querés
  SELECT * FROM ClienteContrato
  WHERE idClienteContrato IN (
    SELECT TOP (@@ROWCOUNT) idClienteContrato FROM ClienteContrato ORDER BY idClienteContrato DESC
  );
END
GO

---sp_clienteContrato_listarTodos
use AltosDelValle
GO
CREATE or alter PROCEDURE  sp_clienteContratoListarTodos
AS
BEGIN
  SELECT 
    cc.idClienteContrato,
    cc.idContrato,
    c.identificacion,
    c.nombre AS nombreCliente,
    tr.nombre AS rol
  FROM ClienteContrato cc
  INNER JOIN Cliente c ON cc.identificacion = c.identificacion
  INNER JOIN TipoRol tr ON cc.idRol = tr.idRol
  ORDER BY cc.idClienteContrato ASC;
END
GO

----sp_clienteContrato_porContrato
use AltosDelValle
GO
CREATE or alter PROCEDURE  sp_clienteContratoPorContrato
  @idContrato INT
AS
BEGIN
  SELECT 
    cc.idClienteContrato,
    cc.idContrato,
    c.identificacion,
    c.nombre AS nombreCliente,
    tr.nombre AS rol
  FROM ClienteContrato cc
  INNER JOIN Cliente c ON cc.identificacion = c.identificacion
  INNER JOIN TipoRol tr ON cc.idRol = tr.idRol
  WHERE cc.idContrato = @idContrato;
END
GO

---sp_clienteContrato_porCliente
use AltosDelValle
GO
CREATE or alter PROCEDURE  sp_clienteContratoPorCliente
  @identificacion INT
AS
BEGIN
  -- 🔹 Selecciona todos los contratos en los que ha participado el cliente dado,
  -- mostrando su rol (comprador, inquilino, etc.)
  SELECT 
    cc.idClienteContrato,
    cc.idContrato,
    c.identificacion,
    c.nombre AS nombreCliente,
    tr.nombre AS rol
  FROM ClienteContrato cc
  INNER JOIN Cliente c ON cc.identificacion = c.identificacion
  INNER JOIN TipoRol tr ON cc.idRol = tr.idRol
  WHERE cc.identificacion = @identificacion
  ORDER BY cc.idClienteContrato ASC;
END
GO

----sp_clienteContrato_porRol
use AltosDelValle
GO
CREATE or alter PROCEDURE  sp_clienteContratoPorRol
  @idRol INT
AS
BEGIN
  -- Retorna todos los vínculos cliente-contrato con el rol especificado
  SELECT 
    cc.idClienteContrato,
    cc.idContrato,
    c.identificacion,
    c.nombre AS nombreCliente,
    tr.nombre AS rol
  FROM ClienteContrato cc
  INNER JOIN Cliente c ON cc.identificacion = c.identificacion
  INNER JOIN TipoRol tr ON cc.idRol = tr.idRol
  WHERE cc.idRol = @idRol
  ORDER BY cc.idClienteContrato ASC;
END
GO

---INSERT PARA TIPO DE ROL 
USE AltosDelValle; 
INSERT INTO TipoRol (nombre) VALUES 
  ('Inquilino'),
  ('Arrendatario'),
  ('Comprador'),
  ('Vendedor');
GO