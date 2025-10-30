USE master;
GO
CREATE LOGIN usuarioCliente 
WITH PASSWORD = 'Cliente123!',
    CHECK_POLICY = ON,
    CHECK_EXPIRATION = OFF;
GO

USE AltosDelValle;
GO
CREATE USER usuarioCliente FOR LOGIN usuarioCliente;
GO

CREATE ROLE rolClienteUsuario;
GO

GRANT SELECT, INSERT, UPDATE ON dbo.Cliente  TO rolClienteUsuario;
GRANT SELECT, INSERT, UPDATE ON dbo.TipoRol TO rolClienteUsuario;
GO

EXEC sp_addrolemember 'rolClienteUsuario', 'usuarioCliente';
GO


select * from Propiedad
GO
