SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[adm_arnewnum_sp] @trx_type	smallint, 
					@tcn_cnt 	int = 1,
					@firstnum	int OUTPUT, 
					@mask		varchar(16) OUTPUT


AS DECLARE	
		@result	smallint,
		@tran_started	smallint,
		@num_type	int

BEGIN
	if isnull(@tcn_cnt,0) = 0
          select @tcn_cnt = 1

	IF (@trx_type = 2031)
		SELECT @num_type = 2000
	
	ELSE IF (@trx_type = 2051)
		SELECT @num_type = 2080
	
	ELSE IF (@trx_type IN (2111, 2112, 2113, 2121))
		SELECT @num_type = 2010
	
	ELSE IF (@trx_type = 2151)
		SELECT @num_type = 2030
	
	ELSE IF (@trx_type = 2032)
		SELECT @num_type = 2020

	SELECT @tran_started = 0
	IF ( @@trancount = 0 )
	BEGIN
		BEGIN TRAN
		SELECT	@tran_started = 1
	END

	UPDATE 	ewnumber
	SET 	next_num = next_num + @tcn_cnt
	WHERE 	num_type = @num_type

	IF (@@error != 0)
	BEGIN
  	  IF (@tran_started = 1)
	    ROLLBACK TRANSACTION
	  RETURN -1
	END

	SELECT 	@firstnum = next_num - @tcn_cnt,
		@mask = rtrim(mask)
	FROM 	ewnumber
	WHERE 	num_type = @num_type

	IF (@@error != 0)
	BEGIN
  	  IF (@tran_started = 1)
	    ROLLBACK TRANSACTION
	  RETURN -1
	END

	IF (@tran_started = 1)
		COMMIT TRANSACTION
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[adm_arnewnum_sp] TO [public]
GO
