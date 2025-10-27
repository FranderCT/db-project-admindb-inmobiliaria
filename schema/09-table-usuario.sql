use AltosDelValle
go

create table RolUsuario (
     idRolUsuario int identity(1,1),
	 nombre varchar(30) not null unique,
 );

 alter table RolUsuario 
 add constraint PK_RolUsuario primary key (idRolUsuario);
 go

 create table Usuario (
     idUsuario int identity(1,1),
     nombre varchar(30) not null,
     apellido1 varchar(30) not null,
     apellido2 varchar(30) null,
     email varchar(50) not null unique,
     password varchar(255) not null,
     telefono varchar(30) null,
     idRolUsuario int not null,
     estado bit not null default 1
 );
go

 alter table Usuario
 add constraint PK_Usuario primary key (idUsuario);
 go

 alter table Usuario
 add constraint FK_RolUsuario
 foreign key (idRolUsuario) references RolUsuario(idRolUsuario);
 go



