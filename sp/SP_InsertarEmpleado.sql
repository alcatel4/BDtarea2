CREATE PROCEDURE dbo.procInsertarEmpleado
     @inValorDocumentoIdentidad VARCHAR(64)
    ,@inNombre VARCHAR (64)
    ,@inIdPuesto INT
    ,@outResultCode INT OUTPUT

    ,@inUsername VARCHAR(64) -- Username del usuario que intenta hacer la inserción
    ,@inPostInIP VARCHAR(64) -- IP del usuario que intenta hacer la inserción
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @IdUsuario INT
    DECLARE @ValorID VARCHAR(64)
    DECLARE @Nombre VARCHAR(64)
    DECLARE @NombrePuesto VARCHAR(64)
    DECLARE @DescError VARCHAR(256)
    SET @outResultCode = 0

    BEGIN TRY

        -- Verifica que TODOS los caracteres sean numéricos
        IF (@inValorDocumentoIdentidad LIKE '%[^0-9]%')
        BEGIN
            SET @outResultCode = 50010
            RETURN
        END
        -- Verificar que el nombre debe ser alfabético y puede contener espacios entre nombre y apellidos
        IF (@inNombre LIKE '%[^a-zA-Z ]%')
        BEGIN
            SET @outResultCode = 50009
            RETURN
        END

        SELECT @ValorID = e.ValorDocumentoIdentidad
        FROM dbo.Empleado AS e
        WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
        -- Verifica que el valor del documento de identidad no esté repetido en la base de datos
        IF (@ValorID = @inValorDocumentoIdentidad)
        BEGIN
            SET @outResultCode = 50004
            RETURN
        END

        SELECT @Nombre = e.Nombre
        FROM dbo.Empleado AS e
        WHERE (e.Nombre = @inNombre)
        -- Verificar que el nombre no esté repetido en la base de datos
        IF (@Nombre = @inNombre)
        BEGIN
            SET @outResultCode = 50005
            RETURN
        END

        SELECT @IdUsuario = u.Id
        FROM dbo.Usuario AS u
        WHERE (u.Username = @inUsername)

        SELECT @NombrePuesto = p.Nombre
        FROM dbo.Puesto AS p
        WHERE (p.Id = @inIdPuesto)

        BEGIN TRANSACTION
            INSERT INTO dbo.Empleado (
                 IdPuesto
                ,ValorDocumentoIdentidad
                ,Nombre
                ,FechaContratacion
                ,SaldoVacaciones
                ,EsActivo
            )
            VALUES (
                 @inIdPuesto
                ,@inValorDocumentoIdentidad
                ,@inNombre
                ,GETDATE()
                ,0
                ,1
            )

            -- Bitácora de eventos
            INSERT INTO dbo.BitacoraEvento (
                 idTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostInIP
                ,PostTime
            )
            VALUES (
                 6
                ,@inValorDocumentoIdentidad + ' ' + @inNombre + ' ' + @NombrePuesto
                ,@idUsuario
                ,@inPostInIP
                ,GETDATE()
            )
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH

        SELECT @DescError = er.Descripcion
        FROM dbo.Error AS er
        WHERE (er.Codigo = @outResultCode)

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

        -- Bitácora de eventos
        INSERT INTO dbo.BitacoraEvento (
                 idTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostInIP
                ,PostTime
        )
        VALUES (
             5
            ,@DescError + ' ' + @inValorDocumentoIdentidad + ' ' + @inNombre + ' ' + @NombrePuesto
            ,@idUsuario
            ,@inPostInIP
            ,GETDATE()
        )

        SET @outResultCode = 50008
    END CATCH
END
