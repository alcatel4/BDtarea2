CREATE PROCEDURE dbo.procActualizarEmpleado
	 @inValorDocumentoIdentidadAnterior VARCHAR(64) -- Esta variable es para identificar al que se va a editar
	,@inValorDocumentoIdentidadNuevo VARCHAR(64)
	,@inNombre VARCHAR(64)
	,@inIdPuesto INT
	,@inUsername VARCHAR(64)
	,@inPostInIP VARCHAR(64)
	,@outResultCode INT OUTPUT

AS
BEGIN

	SET NOCOUNT ON

	-- Lo que tiene que contener la descripción de la bitácora
	DECLARE @DescripcionError VARCHAR(64)
	DECLARE @NombreAnterior VARCHAR(64)
	DECLARE @NombrePuestoAnterior VARCHAR(64)
	DECLARE @NombrePuestoNuevo VARCHAR(64)
	DECLARE @SaldoVacaciones MONEY -- No es editable pero se muestra

	DECLARE @NombreExistente VARCHAR(64)
	DECLARE @ValorDocIdExistente VARCHAR(64)

	DECLARE @IdTipoEvento INT
	DECLARE @IdUsuario INT
	DECLARE @DescripcionEvento VARCHAR(256)

	SET @outResultCode = 0;

	BEGIN TRY

	IF (@inValorDocumentoIdentidadNuevo LIKE '%[^0-9]%')
	BEGIN
		SET @outResultCode = 50010;
	END

	ELSE IF (@inNombre LIKE '%[^a-zA-Z ]%')
	BEGIN
		SET @outResultCode = 50009;
	END

	SELECT @IdUsuario = u.Id
	FROM dbo.Usuario AS u
	WHERE (u.Username = @inUsername);

	-- Obtener los valores del anterior en base a @inValorDocumentoIdentidadAnterior
	SELECT @NombreAnterior = e.Nombre
		   ,@NombrePuestoAnterior = p.Nombre
		   ,@SaldoVacaciones = e.SaldoVacaciones
	FROM dbo.Empleado AS e
	INNER JOIN dbo.Puesto AS p ON (e.IdPuesto = p.Id)
	WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidadAnterior);

	-- Obtener el nombre del puesto nuevo mediante @inIdPuesto
	SELECT @NombrePuestoNuevo = p.Nombre
	FROM dbo.Puesto AS p
	WHERE (p.Id = @inIdPuesto);

	IF (@outResultCode = 0)
	BEGIN
		-- Validar documento duplicado (ignorando el que estoy editanto mediante el Documento Identidad)
		SELECT @ValorDocIdExistente = e.ValorDocumentoIdentidad
		FROM dbo.Empleado AS e
		WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidadNuevo)
		AND (e.ValorDocumentoIdentidad <> @inValorDocumentoIdentidadAnterior);

		-- Validar nombre duplicado (ignorando el que estoy editanto mediante el Documento Identidad)
		SELECT @NombreExistente = e.Nombre
		FROM dbo.Empleado AS e
		WHERE (e.Nombre = @inNombre)
		AND (e.ValorDocumentoIdentidad <> @inValorDocumentoIdentidadAnterior);

		IF (@ValorDocIdExistente IS NOT NULL)
		BEGIN
			SET @outResultCode = 50006
		END

		ELSE IF (@NombreExistente IS NOT NULL)
		BEGIN
			SET @outResultCode = 50007
		END
	END

	SELECT @DescripcionError = er.Descripcion
	FROM dbo.Error AS er
	WHERE (er.Codigo = @outResultCode);
		
	-- Armar la descripción de evento
	IF (@DescripcionError IS NOT NULL)
	BEGIN
		SET @IdTipoEvento = 7;
		SET @DescripcionEvento = @DescripcionError + 
		                         'Antes: ' + @inValorDocumentoIdentidadAnterior +
								 @NombreAnterior + 
								 @NombrePuestoAnterior +
								 'Después: ' + @inValorDocumentoIdentidadNuevo +
								 @inNombre +
								 @NombrePuestoNuevo +
								 'Saldo Vacaciones: ' + CAST(@SaldoVacaciones AS VARCHAR(64));
	END

	ELSE
	BEGIN
		SET @IdTipoEvento = 8;
		SET @DescripcionEvento = 'Antes: ' + @inValorDocumentoIdentidadAnterior +
								 @NombreAnterior + 
								 @NombrePuestoAnterior +
								 'Después: ' + @inValorDocumentoIdentidadNuevo +
								 @inNombre +
								 @NombrePuestoNuevo +
								 'Saldo Vacaciones: ' + CAST(@SaldoVacaciones AS VARCHAR(64));
	END

	BEGIN TRANSACTION

	-- Si no hubo error en la bitácora
	IF (@outResultCode = 0)
	BEGIN
		UPDATE e
		SET e.IdPuesto = @inIdPuesto
			,e.ValorDocumentoIdentidad = @inValorDocumentoIdentidadNuevo
			,e.Nombre = @inNombre
		FROM dbo.Empleado AS e
		WHERE (e.ValorDocumentoIdentidad = @inValorDocumentoIdentidadAnterior)
	END

	-- Insertar dentro de la bitácora de eventos
	INSERT INTO dbo.BitacoraEvento(
		idTipoEvento
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