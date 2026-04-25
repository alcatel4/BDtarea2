CREATE PROCEDURE dbo.procInsertarEmpleado
     @inValorDocumentoIdentidad VARCHAR(64)
    ,@inNombre VARCHAR (64)
    ,@inIdPuesto INT
    ,@inUsername VARCHAR(64) -- Username del usuario que intenta hacer la inserción
    ,@inPostInIP VARCHAR(64) -- IP del usuario que intenta hacer la inserción
    ,@outResultCode INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @IdUsuario INT
    DECLARE @ValorID VARCHAR(64)
    DECLARE @NombreExistente VARCHAR(64)
    DECLARE @NombrePuesto VARCHAR(64)
    DECLARE @DescError VARCHAR(256)

    DECLARE @IdTipoEvento INT
    DECLARE @DescripcionEvento VARCHAR(256)

    SET @outResultCode = 0;

    BEGIN TRY

        -- Verifica que TODOS los caracteres sean numéricos
        IF (@inValorDocumentoIdentidad LIKE '%[^0-9]%')
        BEGIN
            SET @outResultCode = 50010
        END;

        -- Verificar que el nombre debe ser alfabético y puede contener espacios entre nombre y apellidos
        ELSE IF (@inNombre LIKE '%[^a-zA-Z ]%')
        BEGIN
            SET @outResultCode = 50009
        END;

        SELECT @IdUsuario = u.Id
        FROM dbo.Usuario AS u
        WHERE (u.Username = @inUsername);

        SELECT @NombrePuesto = p.Nombre
        FROM dbo.Puesto AS p
        WHERE (p.Id = @inIdPuesto);

        SELECT @ValorID = e.ValorDocumentoIdentidad
               ,@NombreExistente = e.Nombre
        FROM dbo.Empleado AS e
        WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)
        OR (e.Nombre = @inNombre);

        -- Verifica que el valor del documento de identidad no esté repetido en la base de datos
        IF (@ValorID = @inValorDocumentoIdentidad)
        BEGIN
            SET @outResultCode = 50004
        END;

        -- Verificar que el nombre no esté repetido en la base de datos
        ELSE IF (@NombreExistente = @inNombre)
        BEGIN
            SET @outResultCode = 50005
        END;

        -- Registro de bitácora fallida, siempre que haya un error de validación
        IF (@outResultCode <> 0)
        BEGIN
            SELECT @DescError = er.Descripcion
            FROM dbo.Error AS er
            WHERE (er.Codigo = @outResultCode)
 
            SET @IdTipoEvento = 5
            SET @DescripcionEvento = @DescError + ' ' + @inValorDocumentoIdentidad + ' ' + @inNombre + ' ' + @NombrePuesto
        END;

        ELSE
        BEGIN
            SET @IdTipoEvento = 6
            SET @DescripcionEvento = @inValorDocumentoIdentidad + ' ' + @inNombre + ' ' + @NombrePuesto
        END;

        BEGIN TRANSACTION
            IF (@outResultCode = 0)
            BEGIN
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
                );
            END;

            -- Bitácora de eventos
            INSERT INTO dbo.BitacoraEvento (
                idTipoEvento
                ,Descripcion
                ,IdPostByUser
                ,PostInIP
                ,PostTime
            )
            VALUES (
                @TipoEvento
                ,@DescripcionEvento
                ,@idUsuario
                ,@inPostInIP
                ,GETDATE()
            );
        COMMIT TRANSACTION

    END TRY;

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

        SET @outResultCode = 50008
    END CATCH;
END;