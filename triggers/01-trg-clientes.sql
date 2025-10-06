-- TRIGGERS TABLA CLIENTE

--Evita que un cliente sea desactivado si tiene facturas asociadas (en FacturaCliente).
CREATE TRIGGER trg_evitarDesactivarClienteFacturas
ON Cliente
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM FacturaCliente fc
        INNER JOIN deleted d ON fc.identificacion = d.identificacion
    )
    BEGIN
        RAISERROR('No se puede desactivar el cliente porque tiene facturas pendientes.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Si no tiene facturas pendientes, se desactiva en lugar de eliminar
    UPDATE Cliente
    SET estado = 0
    WHERE identificacion IN (SELECT identificacion FROM deleted);
END;
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

-- Evita que se desactive un cliente que tenga propiedades registradas.
 CREATE TRIGGER trg_evitarDesactivarClienteConPropiedades
ON Cliente
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Propiedad p
        INNER JOIN deleted d ON p.identificacion = d.identificacion
    )
    BEGIN
        RAISERROR('No se puede desactivar el cliente porque tiene propiedades registradas.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Si no tiene propiedades, se desactiva el cliente
    UPDATE Cliente
    SET estado = 0
    WHERE identificacion IN (SELECT identificacion FROM deleted);
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

