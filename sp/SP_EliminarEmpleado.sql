CREATE PROCEDURE dbo.procEliminarEmpleado

    @inUsername VARCHAR(64) -- Nombre de usuario que intenta hacer la eliminación
    ,@inPostInIP VARCHAR(64) -- IP del usuario que intenta hacer la eliminación
    ,@inValorDocumentoIdentidad VARCHAR(64) -- Valor para identificar al empleado a eliminar
    ,@inConfirmacionEliminacion BIT -- Confirmación de eliminación (1 si fue confirmado, 0 si fue cancelado)
    ,@outResultCode INT OUTPUT

AS
BEGIN

    SET NOCOUNT ON

    -- Variables para la bitacora de eventos
    DECLARE @NombreEmpleado VARCHAR(64)
    DECLARE @NombrePuestoEmpleado VARCHAR(64)
    DECLARE @SaldoVacacionesEmpleado MONEY
    DECLARE @DescripcionEvento VARCHAR(256)

    DECLARE @IdUsuario INT -- ID del usuario que realiza la eliminación
    DECLARE @IdTipoEvento INT -- ID del tipo de evento para la bitacora (9 = intento de borrado, 10 = eliminacion confirmada)

    SET @outResultCode = 0;

    BEGIN TRY

    -- Obtener los datos del empleado a eliminar para la bitacora
    SELECT @NombreEmpleado = e.Nombre
           ,@NombrePuestoEmpleado = p.Nombre
           ,@SaldoVacacionesEmpleado = e.SaldoVacaciones
    FROM dbo.Empleado AS e
    INNER JOIN dbo.Puesto AS p ON (e.IdPuesto = p.Id)
    WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad);

    SELECT @IdUsuario = u.Id
    FROM dbo.Usuario AS u
    WHERE (u.Username = @inUsername)

    IF (@inConfirmacionEliminacion = 0)
    BEGIN
        SET @IdTipoEvento = 9; -- Intento de borrado
    END

    ELSE
    BEGIN
        SET @IdTipoEvento = 10; -- Eliminación confirmada
    END

    SET @DescripcionEvento = @inValorDocumentoIdentidad + ' - ' + @NombreEmpleado + ' - ' + @NombrePuestoEmpleado + ' - ' + CAST(@SaldoVacacionesEmpleado AS VARCHAR(32));

    BEGIN TRANSACTION

        IF (@inConfirmacionEliminacion = 1)
        BEGIN
            -- Si fue confirmado hay que cambiar el estado del empleado en EsActivo a 0
            UPDATE e
            SET e.EsActivo = 0
            FROM dbo.Empleado AS e
            WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad);
        END

        -- Sea cual sea el caso hay que insertar el evento en la bitacora
        INSERT INTO dbo.BitacoraEvento (
             IdTipoEvento
            ,Descripcion
            ,IdPostByUser
            ,PostInIP
            ,PostTime
        )
        VALUES(
            @IdTipoEvento
            ,@DescripcionEvento
            ,@IdUsuario
            ,@inPostInIP
            ,GETDATE()
        )

    COMMIT TRANSACTION

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