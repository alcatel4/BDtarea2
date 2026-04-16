CREATE PROCEDURE dbo.procLogin
@inUsername VARCHAR(64) --Variable para identificar el username
,@inPassword VARCHAR(64) --Variable para identificar la password
,@inPostInIP VARCHAR(64) --Variable para identificar la IP
,@outResultCode INT OUTPUT --Variable de salida de ResulCode(Estandares)
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @IdUsuario INT 
    DECLARE @PassUsuario VARCHAR(64)
    DECLARE @CountIntentos INT
   
    BEGIN TRY
        --Combrobamos que el usuario sea igual al de la bd
        SELECT @IdUsuario = u.Id 
        FROM dbo.Usuario AS u 
        WHERE (u.Username = @inUsername)

        --Si el usuario no coincide tira codigo de error
        IF(@IdUsuario IS NULL) 
        BEGIN
            SET @outResultCode=50001
            RETURN
        END

        --Comprobamos la cantidad de intentos del usuario en >20 minutos
        SELECT @CountIntentos = COUNT(b.Id) 
        FROM dbo.BitacoraEvento AS b
        WHERE (b.IdTipoEvento = 2) 
        AND (b.IdPostByUser = @IdUsuario) 
        AND (b.PostTime >= DATEADD(MINUTE, -20, GETDATE()))

        --Si los intentos superan los 5 tira codigo de error
        IF(@CountIntentos>5)
        BEGIN
            SET @outResultCode = 50003
            RETURN
        END

        --Comprobamos que la contraseña del usuario sea la misma
        SELECT @PassUsuario = u.Password
        FROM dbo.Usuario AS u
        Where (u.Username = @inUsername) 
        AND (u.Password = @inPassword)

        --Si la contraseña no coincide tira codigo de error
        IF(@PassUsuario IS NULL)
        BEGIN
            SET @outResultCode=50002
            RETURN
        END

        --Insertamos los datos en la Bitacora de los eventos
        INSERT INTO dbo.BitacoraEvento(
            IdTipoEvento
            ,Descripcion
            ,IdPostByUser
            ,PostInIP
            ,PostTime
        )VALUES(
            1
            ,'Login Exitoso'
            ,@IdUsuario
            ,@inPostInIP
            ,GETDATE()
        )
        SET @outResultCode = 0
    
    END TRY
    BEGIN CATCH
        --Se inserta el Error ocasionado por la bd
        INSERT INTO dbo.DBError(
            UserName
            ,Number
            ,State
            ,Severity
            ,Line
            ,[Procedure]
            ,Message
            ,DateTime
        )VALUES(
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