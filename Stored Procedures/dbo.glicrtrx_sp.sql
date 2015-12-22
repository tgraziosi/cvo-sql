SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE 	PROCEDURE	[dbo].[glicrtrx_sp]	@process_ctrl_num	varchar(16),
					@org_company_code      	varchar(8),
					@rec_company_code      	varchar(8),
					@org_home_cur_code	varchar(8),
					@rec_home_cur_code	varchar(8),
					@org_oper_cur_code	varchar(8),
					@rec_oper_cur_code	varchar(8),
					@user_id		smallint,
					@debug			smallint = 0

AS

BEGIN
	DECLARE		@journal_ctrl_num	varchar(16),
			@new_journal_ctrl_num	varchar(16),
			@result			int,
			@rec_home_amount	float,
			@rec_oper_amount	float,
			@rec_nat_cur_code	varchar(8),
			@rec_nat_amount		float,
			@org_nat_cur_code	varchar(8),
			@org_nat_balance	float,
			@org_home_balance	float,
			@org_oper_balance	float,
			@org_sequence_id	int,
			@rec_sequence_id	int,
			@description		varchar(40),
			@journal_description	varchar(30),
			@journal_type		varchar(8),
			@date_entered		int,
			@date_applied		int,
			@source_batch_code	varchar(16),
			@type_flag		smallint,
			@app_id			smallint,
			@reference_code		varchar(32),
			@rate_mode		smallint,
			@account_code		varchar(32),
			@document_2		varchar(16),
			@rec_currency_code	varchar(8),
			@rec_rate_used		float,
			@rec_rate_oper		float,
			@rate_type_home		varchar(8),
			@rate_type_oper		varchar(8),
			@work_time		datetime,
			@org_id			varchar(30)
			
	IF ( @debug > 2 )
	BEGIN
		SELECT	"--------------------- Entering glicrtrx_sp -----------------------"
		SELECT	"Originating company: "+@org_company_code
		SELECT	"Recipient   company: "+@rec_company_code
		SELECT	@work_time = getdate()
	END
	


	SELECT	@journal_type = journal_type,
		@rate_type_home =  rate_type_home,
		@rate_type_oper = rate_type_oper,
		@rate_mode = rate_mode
	FROM	glcoco_vw
	WHERE	org_code = @org_company_code
	AND	rec_code = @rec_company_code
	
	IF ( @journal_type IS NULL )
		RETURN	1014
	
	IF ( @debug > 3 )
	BEGIN
		SELECT	"*** glicrtrx_sp - rate mode    = "+convert( char(4), @rate_mode )
		SELECT	"*** glicrtrx_sp - journal type = "+ @journal_type
	END		
	



	SELECT	@new_journal_ctrl_num = MIN( new_journal_ctrl_num )
	FROM	#new_trx
	
	WHILE ( @new_journal_ctrl_num IS NOT NULL )
	BEGIN
		




		SELECT	@journal_ctrl_num = NULL
		
		SELECT	@journal_ctrl_num = MIN( journal_ctrl_num )
		FROM	#gldtrdet
		WHERE	rec_company_code = @rec_company_code
		AND	mark_flag = 0

		





		IF ( @journal_ctrl_num  IS NULL )
			RETURN 	1039
			
		



		SELECT	@journal_description = journal_description,
			@date_entered = date_entered,
			@date_applied = date_applied,
			@source_batch_code = batch_code,
			@type_flag = type_flag,
			@app_id = app_id
		FROM	gltrx
		WHERE	journal_ctrl_num = @journal_ctrl_num

		
		SELECT @org_id = MAX(org_id)
		FROM gltrxdet 
		WHERE	rec_company_code = @rec_company_code
			AND journal_ctrl_num = @journal_ctrl_num

		IF (@debug > 2)
		BEGIN
		SELECT "	  gltrx crh "	+ @process_ctrl_num +
						+@journal_type +
						@new_journal_ctrl_num +
						@journal_description 
		SELECT "SOurce batch code " +
						@source_batch_code +
						@rec_company_code +
						@org_company_code  +
						@rec_home_cur_code +
						@journal_ctrl_num
		SELECT "  trx type " + @rec_oper_cur_code 
		END

		


		EXEC	@result = gltrxcrh_sp	@process_ctrl_num,
						-1,
						6000,
						2,
						@journal_type,
						@new_journal_ctrl_num,
						@journal_description,
						@date_entered,
						@date_applied,
						0,	
						0,	
						0,	
						@source_batch_code,
						@type_flag,
						@rec_company_code,
						@org_company_code,
						@rec_home_cur_code,
						@journal_ctrl_num,
						112,
						@user_id,
						0,	
						@rec_oper_cur_code,
						5,
						@org_id,
						0

		IF ( @result != 0 )
			RETURN	@result
		







		EXEC	@result = glicusrh_sp	@process_ctrl_num,
						@org_company_code,
						@rec_company_code,
						@journal_ctrl_num,
						@new_journal_ctrl_num
		IF ( @result != 0 )
			RETURN	@result
			
			
		WHILE 0 = 0
		BEGIN
			



			SELECT	@org_sequence_id = NULL
			
			SELECT	@org_sequence_id = MIN( sequence_id )
			FROM	#gldtrdet
			WHERE	journal_ctrl_num = @journal_ctrl_num
			AND	rec_company_code = @rec_company_code
			AND	mark_flag = 0
			


			IF ( @org_sequence_id IS NULL )
				break
			



			SELECT	@org_home_balance = balance,
				@org_nat_balance  = nat_balance,
				@org_nat_cur_code = nat_cur_code,
				@org_oper_balance = balance_oper,
				@account_code = account_code
			FROM	#gldtrdet
			WHERE	journal_ctrl_num = @journal_ctrl_num
			AND	sequence_id = @org_sequence_id
			


			SELECT	@description = description,
				@document_2 = document_2,
				@reference_code = reference_code
			FROM	gltrxdet
			WHERE	journal_ctrl_num = @journal_ctrl_num
			AND	sequence_id = @org_sequence_id
				
			

	
			EXEC	@result = glicrate_sp
				@date_applied,
				@org_home_cur_code, 
				@org_home_balance,
				@org_nat_cur_code, 
				@org_nat_balance,
				@org_oper_cur_code,
				@org_oper_balance,
				@rate_mode,  
				@rate_type_home,
				@rate_type_oper,
				@rec_home_cur_code,
				@rec_oper_cur_code,
				@rec_home_amount	OUTPUT,
				@rec_oper_amount	OUTPUT,
				@rec_nat_cur_code	OUTPUT,
				@rec_nat_amount		OUTPUT, 
				@rec_rate_used		OUTPUT,
				@rec_rate_oper		OUTPUT

			IF ( @result != 0 )
				RETURN	@result
			


			EXEC	@result = gltrxcrd_sp	6000,
							2,
							@new_journal_ctrl_num,
							@rec_sequence_id OUTPUT,
							@rec_company_code,
							@account_code,
							@description,
							@journal_ctrl_num,
							@document_2,
							@reference_code,
							@rec_home_amount,
							@rec_nat_amount,
							@rec_nat_cur_code,
							@rec_rate_used,
							112,
							@org_sequence_id,
							@rec_oper_amount,
							@rec_rate_oper,
							@rate_type_home,
							@rate_type_oper,
							0,
							@org_id

			IF ( @result != 0 )
				RETURN	@result
			







			EXEC	@result = glicusrd_sp	@process_ctrl_num,
							@org_company_code,
							@rec_company_code,
							@journal_ctrl_num,
							@new_journal_ctrl_num,
							@org_sequence_id,
							@rec_sequence_id
			IF ( @result != 0 )
				RETURN	@result
				
			UPDATE	#gldtrdet
			SET	mark_flag = 1
			WHERE	journal_ctrl_num = @journal_ctrl_num
			AND	sequence_id = @org_sequence_id
			
		END
		


		IF ( @debug > 4 )
		BEGIN
			SELECT	"*** Created transaction: "+@new_journal_ctrl_num+
				" from transaction "+@journal_ctrl_num
			SELECT	"Execution time: "+
			        convert( varchar(30), datediff( ms, @work_time, getdate() ) )
			SELECT	@work_time = getdate()
		END
		


		DELETE	#new_trx
		WHERE	new_journal_ctrl_num = @new_journal_ctrl_num
		
		

	
		SELECT	@new_journal_ctrl_num = NULL
		SELECT	@new_journal_ctrl_num = MIN( new_journal_ctrl_num )
		FROM	#new_trx
	END
	
	RETURN	@result
END
GO
GRANT EXECUTE ON  [dbo].[glicrtrx_sp] TO [public]
GO
