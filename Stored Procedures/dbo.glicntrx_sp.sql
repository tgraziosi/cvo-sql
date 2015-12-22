SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE 	PROCEDURE	[dbo].[glicntrx_sp]	@company_code	varchar(8),
					@debug		smallint = 0

AS

BEGIN
	DECLARE	@journal_ctrl_num	varchar(16),
		@n			int,
		@result			int
		
		
	SELECT	@n = COUNT (DISTINCT journal_ctrl_num)
	FROM	#gldtrdet d
	WHERE	d.rec_company_code = @company_code
	
	IF ( @debug > 4 )
	BEGIN
		SELECT	"*** glicntrx_sp -  "+convert( char(6), @n )+
			" transaction numbers will be created"
	END
	
	WHILE @n > 0
	BEGIN
		EXEC	@result = gltrxnew_sp	@company_code,
						@journal_ctrl_num OUTPUT
		IF ( @result != 0 )
			RETURN	@result
			
		INSERT	#new_trx (
			journal_ctrl_num,
			new_journal_ctrl_num,
			flag_type )
		SELECT	" ",
			@journal_ctrl_num,
			0
			
		IF ( @@error != 0 )
			RETURN	1039
			
		IF ( @debug > 5 )
		BEGIN
			SELECT	"*** glicntrx_sp -  transaction number "+
				convert(char(20), @journal_ctrl_num )+
				" created "
		END
	
		SELECT	@n = @n - 1
	END
	
	RETURN	@result
END
GO
GRANT EXECUTE ON  [dbo].[glicntrx_sp] TO [public]
GO
