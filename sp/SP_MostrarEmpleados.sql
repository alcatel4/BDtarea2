CREATE PROCEDURE dbo.procMostrarEmpleados
	@inFiltro VARCHAR(64) -- Filtro de busqueda
	,@inUsername VARCHAR(64) 
	,@inPostInIP VARCHAR(64) 
	,@outResultCode INT OUTPUT 
AS
BEGIN
	DECLARE @IdUsuario INT
	DECLARE @IdTipoEvento INT
	DECLARE @DescripcionEvento VARCHAR(64)

	SET NOCOUNT ON
	SET @outResultCode = 0

	BEGIN TRY

	SELECT @IdUsuario = u.Id
    FROM dbo.Usuario AS u
    WHERE (u.Username = @inUsername)

	IF (@inFiltro = '')
	BEGIN
		SELECT e.ValorDocumentoIdentidad, e.Nombre
		FROM dbo.Empleado AS e
		WHERE (e.EsActivo = 1)
		ORDER BY e.Nombre ASC
	END
	ELSE
		IF (ISNUMERIC(@inFiltro) = 1)
		BEGIN
			SELECT e.ValorDocumentoIdentidad, e.Nombre
			FROM dbo.Empleado AS e
			WHERE (e.ValorDocumentoIdentidad LIKE '%' + @inFiltro + '%') --Busca que @inFiltro este la identidad
				AND (e.EsActivo = 1)
			ORDER BY e.Nombre ASC
			SET @IdTipoEvento = 12
			SET @DescripcionEvento = @inFiltro
		END
		ELSE
			BEGIN
				SELECT e.ValorDocumentoIdentidad, e.Nombre
				FROM dbo.Empleado AS e
				WHERE (e.Nombre LIKE '%' + @inFiltro + '%') --Busca que @inFiltro este en el nombre
					AND (e.EsActivo = 1)
				ORDER BY e.Nombre ASC
				SET @IdTipoEvento = 11
				SET @DescripcionEvento = @inFiltro
			END

	IF (@inFiltro <> '') -- Si el filtro es vacio, no ingresa nada en la bitacora
	BEGIN
	BEGIN TRANSACTION -- Insertar evento en la bitacora
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
    END CATCH
END

	
