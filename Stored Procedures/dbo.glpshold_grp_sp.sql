SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

		
CREATE PROCEDURE	[dbo].[glpshold_grp_sp]  
			@batch_code	varchar(16),
			@debug_level	smallint = 0
						

AS

BEGIN
	DECLARE		@jour_num	varchar(16),
			@client_id	varchar(20),
			@trx_on_hold	varchar(80),
			@batch_mode_on	smallint,
			@e_code		int,
			@post_ctrl_num	varchar(16),
			@post_user_id	smallint,
			@post_date	int,
			@period_end	int,
			@batch_type	smallint,
			@errors_found	smallint,
			@result		int,
			@work_time	datetime
			
	SELECT	@client_id = "POSTTRX", 
		@work_time = getdate()

	EXEC	@result = glgetstr_sp	6, 
					@trx_on_hold OUTPUT
					
	IF ( @result != 0 )
		return @result
	
	


	EXEC	@result = batinfo_group_sp	@batch_code,
					@post_ctrl_num	OUTPUT,
					@post_user_id	OUTPUT,
					@post_date	OUTPUT,
					@period_end	OUTPUT,
					@batch_type	OUTPUT
	IF ( @result != 0 )
		return 1021

	SELECT	@batch_mode_on = batch_proc_flag
	FROM	glco
	
	


	



	IF EXISTS (SELECT   * FROM #hold  )
	BEGIN

		SELECT 	@jour_num = NULL, @errors_found = 1

		SELECT	@jour_num = MIN( journal_ctrl_num )
		FROM	#hold
		WHERE	logged = 0
		
		SELECT	@e_code = MIN( e_code )
		FROM	#hold
		WHERE	journal_ctrl_num = @jour_num
		
		IF ( @batch_mode_on = 1 )
			EXEC	batupdst_grp_sp	@batch_code,
						5

		IF ( @debug_level > 3 )
		BEGIN	
			SELECT	"Contents of #hold table"
			SELECT	convert( char(24), journal_ctrl_num ) + 
				convert( char(80), e_ldesc )
			FROM	#hold t, glerrdef e
			WHERE	e.e_code = t.e_code
		END

		WHILE ( @jour_num IS NOT NULL )
		BEGIN
			WHILE ( @e_code IS NOT NULL )
			BEGIN
				EXEC @result =	glputerr_sp	@client_id, 
							@post_user_id, 
							@e_code, 
							"glpshold_grp.cpp",
							166, 
							@jour_num, 
							@trx_on_hold,
							NULL,
							NULL

				UPDATE	#hold
				SET	logged = 1
				WHERE	journal_ctrl_num = @jour_num
				AND	e_code = @e_code

				SELECT	@e_code = MIN( e_code )
				FROM	#hold
				WHERE	journal_ctrl_num = @jour_num
				AND 		logged = 0

			END

			SELECT	@jour_num = NULL

			SELECT	@jour_num = MIN( journal_ctrl_num )
			FROM	#hold
			WHERE	logged = 0
			
			SELECT	@e_code = MIN( e_code )
			FROM	#hold
			WHERE	journal_ctrl_num = @jour_num

		END
		



		IF ( @debug_level > 3 ) SELECT "glpshold_grp.cpp" + ", line " + STR( 199, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Clearing temp tables of transactions with errors"

		UPDATE	gltrx 

		SET 	hold_flag = 1, 
			posted_flag = 0, 
			process_group_num = " "
		FROM	#hold t, gltrx h
		WHERE 	t.journal_ctrl_num = h.journal_ctrl_num

		DELETE	#gldtrx
		FROM	#hold t, #gldtrx h
		WHERE 	t.journal_ctrl_num = h.journal_ctrl_num
		


		DELETE	#gldtrdet
		FROM	#hold t, #gldtrdet d
		WHERE 	t.journal_ctrl_num = d.journal_ctrl_num

		DELETE	#hold

	END
	
	IF EXISTS (SELECT 1 FROM ibifc WHERE process_ctrl_num = @post_ctrl_num)
		RETURN 202 --E_ERRORS_FOUND
	IF ( @debug_level > 1 ) SELECT "glpshold_grp.cpp" + ", line " + STR( 225, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Exiting"	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[glpshold_grp_sp] TO [public]
GO
