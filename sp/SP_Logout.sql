CREATE PROCEDURE dbo.procLogout
	@inUsername VARCHAR(64)
	,@inPostInIP VARCHAR(64)  
    ,@outResultCode   INT OUTPUT
AS
BEGIN

	SET NOCOUNT ON
	DECLARE @IdUsuario INT
    SET @outResultCode = 0

	BEGIN TRY
		
		SELECT @IdUsuario = u.Id --Selecciona el Id del usuario que se esta cerrando sesion
        FROM dbo.Usuario AS u
        WHERE (u.Username = @inUsername)

		BEGIN TRANSACTION

		INSERT INTO dbo.BitacoraEvento (
                IdTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostInIP
                ,PostTime
            )
            VALUES (
                 4
                ,''
                ,@IdUsuario
                ,@inPostInIP
                ,GETDATE()
            )

        COMMIT TRANSACTION
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


