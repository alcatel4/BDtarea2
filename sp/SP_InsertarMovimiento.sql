CREATE PROCEDURE dbo.procInsertarMovimiento
	@inUsername VARCHAR(64)
	,@inValorDocumentoIdentidad VARCHAR(64)
	,@inTipoMovimiento VARCHAR(64)
	,@inMonto MONEY
	,@inPostInIP VARCHAR(64)
	,@outResultCode INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @IdUsuario INT
	DECLARE @IdEmpleado INT
	DECLARE @NombreEmpleado VARCHAR(64)
	DECLARE @IdTipoMovimiento INT
	DECLARE @IdTipoEvento INT
    DECLARE @DescripcionEvento VARCHAR(256) 
	DECLARE @saldoActual MONEY
	DECLARE @saldoNuevo MONEY
	DECLARE @TipoAccion VARCHAR(64)
    SET @outResultCode = 0

	BEGIN TRY

	SELECT @IdUsuario = u.Id -- Selecciona el id del usuario
	FROM dbo.Usuario AS u
	WHERE (u.Username = @inUsername)

	SELECT @IdEmpleado = e.Id -- Selecciona el ID, nombre y saldo actual del empleado
		,@NombreEmpleado = e.Nombre
		,@saldoActual = e.SaldoVacaciones
	FROM dbo.Empleado as e
	WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidad)

	SELECT @IdTipoMovimiento = m.Id -- Selecciona el ID y el tipo de accion del movimiento
		,@TipoAccion = m.TipoAccion
	FROM dbo.TipoMovimiento as m
	WHERE (m.Nombre = @inTipoMovimiento)

	IF(@TipoAccion = 'Credito') -- Si es credito suma, si es debito resta
	BEGIN
		SET @saldoNuevo = @saldoActual + @inMonto
	END
	ELSE
	BEGIN
		SET @saldoNuevo = @saldoActual - @inMonto
	END
	IF(@saldoNuevo < 0) -- Si el saldoNuevo da negativo salta error
	BEGIN
		SET @outResultCode = 50011
		SET @IdTipoEvento = 13
		SET @DescripcionEvento = 'Monto del movimiento rechazado pues si se aplica, el saldo seria negativo, ' + @inValorDocumentoIdentidad + ', ' + @NombreEmpleado + ', ' + CAST(@saldoActual AS VARCHAR) + ', ' + @inTipoMovimiento + ', ' + CAST(@inMonto AS VARCHAR)
	END
	ELSE
	BEGIN -- Caso exitoso
		SET @outResultCode = 0
        SET @IdTipoEvento = 14
        SET @DescripcionEvento = @inValorDocumentoIdentidad + ', ' + @NombreEmpleado + ', ' + CAST(@saldoNuevo AS VARCHAR) + ', ' + @inTipoMovimiento + ', ' + CAST(@inMonto AS VARCHAR)
    END
		BEGIN TRANSACTION
		IF(@outResultCode = 0) -- Si el caso es exitoso hace el insert a la tabla 
		BEGIN
			INSERT INTO dbo.Movimiento(
				IdEmpleado
				,IdTipoMovimiento
				,Fecha
				,Monto
				,NuevoSaldo
				,IdPostByUser
				,PostInIP
				,PostTime 
			)
			Values (
				@IdEmpleado
				,@IdTipoMovimiento
				,GETDATE()
				,@inMonto
				,@saldoNuevo
				,@IdUsuario
				,@inPostInIP
				,GETDATE()
			)

			UPDATE dbo.Empleado
			SET SaldoVacaciones = @saldoNuevo
			WHERE (Id = @IdEmpleado)

			INSERT INTO dbo.BitacoraEvento(
				IdTipoEvento
				,Descripcion
				,IdPostByUser
				,PostInIP
				,PostTIME
			)
			Values (
				@IdTipoEvento
				,@DescripcionEvento
				,@IdUsuario
				,@inPostInIP
				,GETDATE()
			)
		END
		ELSE
		BEGIN -- En caso contrario hace un insert a la bitacora de eventos
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
		END
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
END;

