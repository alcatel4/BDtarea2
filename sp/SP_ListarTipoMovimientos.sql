CREATE PROCEDURE dbo.procListarTiposMovimiento
    @outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0

    SELECT tm.Nombre
    FROM dbo.TipoMovimiento AS tm
    ORDER BY tm.Nombre ASC
END