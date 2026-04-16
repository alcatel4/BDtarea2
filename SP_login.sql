CREATE PROCEDURE dbo.procLogin
     @inUsername VARCHAR(64)  --Username del usuario
    ,@inPassword VARCHAR(64)  --Password del usuario
    ,@inPostInIP VARCHAR(64)  --IP de origen del login
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @IdUsuario INT
    DECLARE @PassUsuario VARCHAR(64)
    DECLARE @CountIntentos INT
    DECLARE @IdTipoEvento INT
    DECLARE @DescripcionEvento VARCHAR(256)
    DECLARE @outResultCode INT 
    SET @outResultCode = 0

    BEGIN TRY

        SELECT @IdUsuario = u.Id
        FROM dbo.Usuario AS u
        WHERE (u.Username = @inUsername)

        IF (@IdUsuario IS NULL) --Comprueba que el usuario exista
        BEGIN
            SET @outResultCode = 50001
            SELECT @outResultCode AS Codigo
                ,e.Descripcion AS Descripcion
            FROM dbo.Error AS e
            WHERE (e.Codigo = @outResultCode)
            RETURN
        END

        SELECT @CountIntentos = COUNT(b.Id)
        FROM dbo.BitacoraEvento AS b
        WHERE (b.IdTipoEvento = 2)
          AND (b.IdPostByUser = @IdUsuario)
          AND (b.PostTime >= DATEADD(MINUTE, -20, GETDATE()))

        IF (@CountIntentos > 5) --Comprueba que no haya pasado los 5 intentos
        BEGIN
            SET @outResultCode = 50003
            SET @IdTipoEvento = 3
            SET @DescripcionEvento = ''
        END
        ELSE
        BEGIN
            SELECT @PassUsuario = u.Password
            FROM dbo.Usuario AS u
            WHERE (u.Id = @IdUsuario)
              AND (u.Password = @inPassword)

            IF (@PassUsuario IS NULL) --Comprueba los intentos de sesion de fallo contraseña
            BEGIN
                SET @outResultCode = 50002
                SET @IdTipoEvento = 2
                SET @DescripcionEvento = 'Intento: ' +CAST((@CountIntentos+1) AS VARCHAR)+' Error: 50002'
            END
            ELSE
            BEGIN
                SET @outResultCode = 0
                SET @IdTipoEvento = 1
                SET @DescripcionEvento = 'Exitoso'
            END
        END

        BEGIN TRANSACTION

            INSERT INTO dbo.BitacoraEvento (
                 IdTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostInIP
                ,PostTime
            )
            VALUES (
                 @IdTipoEvento
                ,@DescripcionEvento
                ,@IdUsuario
                ,@inPostInIP
                ,GETDATE()
            )

        COMMIT TRANSACTION
        IF (@outResultCode = 0) -- Comprueba caso de exito
        BEGIN
            SELECT @outResultCode AS Codigo
                ,'' AS Descripcion
        END
        ELSE
        BEGIN
            SELECT @outResultCode AS Codigo
                ,e.Descripcion AS Descripcion
            FROM dbo.Error AS e
            WHERE (e.Codigo = @outResultCode)
        END

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
        SELECT @outResultCode AS Codigo
            ,e.Descripcion AS Descripcion
        FROM dbo.Error AS e
        WHERE (e.Codigo = @outResultCode)

    END CATCH
END