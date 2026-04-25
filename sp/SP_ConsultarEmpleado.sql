CREATE PROCEDURE dbo.procConsultarEmpleado

    @inUsername VARCHAR(64) -- Nombre de usuario que intenta hacer la consulta
    ,@inValorDocumentoIdentidad VARCHAR(64) -- Valor del documento de identidad del empleado a consultar
    ,@outResultCode INT OUTPUT

AS
BEGIN
    SET NOCOUNT ON
    SET @outResultCode = 0;

    BEGIN TRY

    SELECT e.ValorDocumentoIdentidad AS ValorDocumentoIdentidad -- Valor del documento de identidad del empleado
           ,e.Nombre AS NombreEmpleado -- Nombre del empleado
           ,p.Nombre AS NombrePuesto -- Nombre del puesto del empleado
           ,e.SaldoVacaciones AS SaldoVacaciones -- Saldo de vacaciones del empleado
    FROM dbo.Empleado AS e
    INNER JOIN dbo.Puesto AS p ON (e.IdPuesto = p.Id)
    WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad);

    END TRY

    BEGIN CATCH

        INSERT INTO dbo.DBError(
             UserName
            ,Number
            ,State
            ,Severity
            ,Line
            ,[Procedure]
            ,Message
            ,DateTime
        )
        VALUES(
             @inUsername
            ,ERROR_NUMBER()
            ,ERROR_STATE()
            ,ERROR_SEVERITY()
            ,ERROR_LINE()
            ,ERROR_PROCEDURE()
            ,ERROR_MESSAGE()
            ,GETDATE()
        )

        SET @outResultCode = 50008;
    END CATCH
END