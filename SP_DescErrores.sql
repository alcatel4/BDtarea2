CREATE PROCEDURE dbo.procErroresLogin
   @inCodigo INT
   ,@outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0

    SELECT e.Descripcion
    FROM dbo.Error AS e
    WHERE (e.Codigo = @inCodigo)
END