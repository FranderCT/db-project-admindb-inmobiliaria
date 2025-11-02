USE AltosDelValle
GO

SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_TYPE = 'PRIMARY KEY'; -- todas las primary keys
GO

SELECT * FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_NAME = 'Propiedad'; -- llaves primarias  de la tabla Propiedad por ejemplo
GO


