use AltosDelValle
go

insert into RolUsuario (nombre) values ('ADMINISTRADOR')
go
insert into RolUsuario (nombre) values ('AGENTE')
go
insert into RolUsuario (nombre) values ('LECTOR')
go

insert into Usuario (nombre, apellido1, email, password, telefono, idrolusuario) 
			values ('Luisito', 'Comunica', 'admin@altosdelvalle.com', '$2b$10$FgcEj06LNMnqvwjTb/cdTOuiVbamdw81.CuKZTtVEPstZTcft2LRu', 80808181, 1)
go
-- admin@altosdelvalle.com
-- password123
select * from usuario
