CREATE PROCEDURE dbo.procInsertarEmpleado
     @inValorDocumentoIdentidad VARCHAR(64)
    ,@inNombre VARCHAR (64)
    ,@inIdPuesto INT
    ,@outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @ValorID VARCHAR(64)
    DECLARE @Nombre VARCHAR(64)
    SET @outResultCode = 0

    BEGIN TRY

        SELECT @ValorID = e.ValorDocumentoIdentidad
        FROM dbo.Empleado AS e
        WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)

        IF (@ValorID = @inValorDocumentoIdentidad)
        BEGIN
            SET @outResultCode = 50004
            RETURN
        END

        SELECT @Nombre = e.Nombre
        FROM dbo.Empleado AS e
        WHERE (e.Nombre = @inNombre)

        IF (@Nombre = @inNombre)
        BEGIN
            SET @outResultCode = 50005
            RETURN
        END

    END TRY
    BEGIN CATCH

    END CATCH
END
