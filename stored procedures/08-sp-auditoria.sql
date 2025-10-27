--- Este sp sirve para establecer el contexto de la sesión con la información del usuario autenticado.
CREATE OR ALTER PROCEDURE sp_SetSessionContext
  @correo NVARCHAR(150),
  @nombreRol NVARCHAR(100)
AS
BEGIN
  -- Establece solo las variables disponibles desde el token
  EXEC sp_set_session_context 'correo', @correo;
  EXEC sp_set_session_context 'nombreRol', @nombreRol;
END;
GO