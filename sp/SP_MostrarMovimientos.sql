CREATE PROCEDURE dbo.procMostrarMovimientos
	@inValorDocumentoIdentidad VARCHAR(64)
    ,@inUsername VARCHAR(64)
	,@outResultCode INT OUTPUT
AS
BEGIN

SET NOCOUNT ON
SET @outResultCode = 0

BEGIN TRY

	SELECT e.ValorDocumentoIdentidad --Selecciona los datos principales
		,e.Nombre
		,e.SaldoVacaciones
	FROM dbo.Empleado AS e
	WHERE (@inValorDocumentoIdentidad = e.ValorDocumentoIdentidad)

	SELECT m.Fecha -- Selecciona todos los datos de los movimienots
		  ,tm.Nombre AS TipoMovimiento
		  ,m.Monto
		  ,m.NuevoSaldo
		  ,u.Username
		  ,m.PostInIP
		  ,m.PostTime
	FROM dbo.Movimiento AS m
    INNER JOIN dbo.Empleado AS e ON (m.IdEmpleado = e.Id)
    INNER JOIN dbo.TipoMovimiento AS tm ON (m.IdTipoMovimiento = tm.Id)
    INNER JOIN dbo.Usuario AS u ON (m.IdPostByUser = u.Id)
	WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
	ORDER BY m.Fecha DESC

    END TRY
    BEGIN CATCH
        INSERT INTO dbo.DBError (
            UserName
            ,Number
            ,State
            ,Severity
            ,Line
            ,[Procedure]
            ,Message
            ,DateTime
        )
        VALUES (
            @inUsername
            ,ERROR_NUMBER()
            ,ERROR_STATE()
            ,ERROR_SEVERITY()
            ,ERROR_LINE()
            ,ERROR_PROCEDURE()
            ,ERROR_MESSAGE()
            ,GETDATE()
        )

        SET @outResultCode = 50008
    END CATCH
END

