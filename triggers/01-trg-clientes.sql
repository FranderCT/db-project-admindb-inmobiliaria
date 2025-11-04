-- TRIGGERS TABLA CLIENTE
use AltosDelValle
go

--TRIGGER Evita desactivar clientes (UPDATE estado = 0)
--si tienen facturas o propiedades asociadas.
CREATE OR ALTER TRIGGER trg_evitarDesactivarClienteUpdate
	ON dbo.Cliente
	FOR UPDATE
	AS
	BEGIN
		SET NOCOUNT ON;

		IF UPDATE(estado)
		BEGIN
			IF EXISTS (
				SELECT 1
				FROM inserted i
				INNER JOIN deleted d ON i.identificacion = d.identificacion
				WHERE d.estado = 1 AND i.estado = 0
			)
			BEGIN
				-- Validar facturas
				IF EXISTS (
					SELECT 1
					FROM dbo.FacturaCliente fc
					INNER JOIN inserted i ON fc.identificacion = i.identificacion
					WHERE i.estado = 0
				)
				BEGIN
					RAISERROR('No se puede desactivar el cliente porque tiene facturas asociadas.', 16, 1);
					ROLLBACK TRANSACTION;
					RETURN;
				END;

				-- Validar propiedades
				IF EXISTS (
					SELECT 1
					FROM dbo.Propiedad p
					INNER JOIN inserted i ON p.identificacion = i.identificacion
					WHERE i.estado = 0
				)
				BEGIN
					RAISERROR('No se puede desactivar el cliente porque tiene propiedades registradas.', 16, 1);
					ROLLBACK TRANSACTION;
					RETURN
				END
			END
		END
	END
	GO

-- Evita insertar o actualizar un cliente con un teléfono ya asignado a otro cliente activo.
CREATE TRIGGER trg_evitarDuplicadosDeTelefonos
ON Cliente
INSTEAD OF INSERT, UPDATE
AS
BEGIN
    -- Verificar duplicados activos
    IF EXISTS (
        SELECT 1
        FROM Cliente c
        INNER JOIN inserted i ON c.telefono = i.telefono
        WHERE c.identificacion <> i.identificacion AND c.estado = 1
    )
    BEGIN
        RAISERROR('El número de teléfono ya está asignado a otro cliente activo.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Realizar inserción o actualización normalmente
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        MERGE Cliente AS target
        USING inserted AS source
        ON target.identificacion = source.identificacion
        WHEN MATCHED THEN
            UPDATE SET
                nombre = source.nombre,
                apellido1 = source.apellido1,
                apellido2 = source.apellido2,
                telefono = source.telefono,
                estado = source.estado
        WHEN NOT MATCHED THEN
            INSERT (identificacion, nombre, apellido1, apellido2, telefono, estado)
            VALUES (source.identificacion, source.nombre, source.apellido1, source.apellido2, source.telefono, source.estado);
    END
END
GO

-- Impide modificar la identificación del cliente (no se desactiva, pero protege la clave).
CREATE TRIGGER trg_evitarUpdateCedula
ON Cliente
FOR UPDATE
AS
BEGIN
    IF UPDATE(identificacion)
    BEGIN
        RAISERROR('No se puede modificar la cédula del cliente.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;
GO