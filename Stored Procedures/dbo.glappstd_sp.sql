SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE  [dbo].[glappstd_sp]
	@app_id  		smallint,
	@app_post_date 		int,
	@process_id 		smallint, 
	@user_id 		smallint,
	@orig_flag		smallint,
	@error_flag 		int = 0 OUTPUT,
	@debug			smallint = 0

AS

BEGIN

	SELECT	@error_flag = 0

	DECLARE @batch_proc_flag	smallint,
		@indirect_flag		smallint,
		@jul_end_date		int,
		@jul_end_time		int,
		@post_time 		int,
		@process_host_id	varchar(8),
		@process_server_id	int,
		@result			int,
		@user_name 		varchar(30),
		@process_ctrl_num	varchar(16),
		@batch_code		varchar(16),
		@errors_found		smallint,
		@company_code		varchar(8),
		@batch_mode_on		smallint,
		@process_count		smallint,
		@str_msg		varchar(255)
		

	SELECT	@company_code = company_code,
		@batch_proc_flag = batch_proc_flag,
		@indirect_flag = indirect_flag			      
	FROM	glco
	


	SELECT	@process_ctrl_num = NULL

	SELECT	@process_ctrl_num = process_ctrl_num
	FROM	#pcontrol

	IF ( @process_ctrl_num IS NULL )
		return	1057

	EXEC	apptime_sp @post_time OUTPUT
		
	





	IF ( @indirect_flag = 0 )
	BEGIN
		IF ( @batch_proc_flag = 1 )
		BEGIN
			UPDATE	gltrx
			SET	posted_flag = 0,
				process_group_num = " "
			FROM	gltrx
			WHERE	batch_code = (	SELECT	DISTINCT batch_ctrl_num
						FROM	batchctl b, gltrx h
						WHERE	b.batch_ctrl_num = h.batch_code
						AND	h.intercompany_flag = 1
						AND	b.process_group_num = @process_ctrl_num )
			
			UPDATE	batchctl
			SET	posted_flag = 0,
				process_group_num = " "
			FROM	batchctl b, gltrx h
			WHERE	b.batch_ctrl_num = h.batch_code
			AND	h.intercompany_flag = 1
			AND	b.process_group_num = @process_ctrl_num 
		END

		ELSE
		BEGIN
			UPDATE	gltrx
			SET	posted_flag = 0,
				batch_code = " ",
				process_group_num = " "
			WHERE	process_group_num = @process_ctrl_num
			AND	intercompany_flag = 1
		END
	END

	



	ELSE
	BEGIN
		IF ( @batch_proc_flag = 1 )
		BEGIN
			UPDATE	gltrx
			SET	posted_flag = 0,
				process_group_num = " "
			FROM	batchctl b, gltrx h
			WHERE	b.batch_ctrl_num = h.batch_code
			AND	b.process_group_num = @process_ctrl_num
			
			UPDATE	batchctl
			SET	posted_flag = 0,
				process_group_num = " "
			WHERE	process_group_num = @process_ctrl_num

		END

		ELSE
		BEGIN
			UPDATE	gltrx
			SET	posted_flag = 0,
				batch_code = " ",
				process_group_num = " "
			WHERE	process_group_num = @process_ctrl_num
		END
	END
		
	




	IF ( 0 = (	SELECT	COUNT(*)
			FROM	gltrx
			WHERE	posted_flag = -1
			AND	process_group_num = @process_ctrl_num ))
	BEGIN
		EXEC	pctrlupd_sp	@process_ctrl_num,
					3
		SELECT	@error_flag = 0

		EXEC appgetstring_sp "STR_POST_COMPLETE", @str_msg OUT

		EXEC	status_sp	"GLAPPSTD", 
					@process_id, 
					@user_id, 
					@str_msg, 
					100, 
					@orig_flag, 
					0
		RETURN @error_flag
		
	END

	


	IF ( @batch_proc_flag = 0 )
	BEGIN
		
		EXEC	@result = glpsmkbt_sp	@process_ctrl_num,
						@company_code,
						@debug
		IF ( @result != 0 )
		BEGIN
			EXEC	pctrlupd_sp	@process_ctrl_num,
						2
			return @result
		END
					
	END

	


	








CREATE TABLE #gldtrx
(
	journal_ctrl_num      		varchar(16)	NOT NULL, 
	date_applied          		int	NOT NULL,
	recurring_flag			smallint	NOT NULL,
	repeating_flag			smallint	NOT NULL,
	reversing_flag			smallint	NOT NULL,
	mark_flag           		smallint	NOT NULL,
	interbranch_flag		smallint	NOT NULL
)

CREATE UNIQUE CLUSTERED	INDEX	#gldtrx_ind_0
ON				#gldtrx ( journal_ctrl_num )

CREATE INDEX	#gldtrx_ind_1
ON		#gldtrx ( mark_flag )




	





























































































CREATE TABLE #gldtrdet
(
        journal_ctrl_num	varchar(16)	NOT NULL,
	sequence_id		int	NOT NULL,
        account_code		varchar(32)	NOT NULL,	
        balance			float	NOT NULL,		
	nat_balance		float	NOT NULL,		
	nat_cur_code		varchar(8)	NOT NULL,	
	rec_company_code	varchar(8)	NOT NULL, 
        mark_flag               smallint        NOT NULL,        

        balance_oper            float   NOT NULL,
        org_id		        varchar(30)   NULL
)


CREATE UNIQUE CLUSTERED INDEX	#gldtrdet_ind_0
ON		  	#gldtrdet ( journal_ctrl_num, sequence_id )

CREATE INDEX	#gldtrdet_ind_1
ON		#gldtrdet ( account_code )



	






























































































CREATE TABLE #hold
(
	journal_ctrl_num  	varchar(16)	NOT NULL, 
	e_code		  	int	NOT NULL,
	logged		  	smallint	NOT NULL
)

CREATE UNIQUE INDEX	#hold_ind_0
ON				#hold ( journal_ctrl_num, e_code )


	




CREATE TABLE	#summary (
		summary_code		varchar(32)	NOT NULL,
		summary_type		tinyint	NOT NULL,
		account_code		varchar(32)	NOT NULL )

CREATE UNIQUE CLUSTERED INDEX	#summary_ind_0
ON     		#summary ( account_code, summary_code, summary_type )

	












	
CREATE TABLE	#sumhdr (
		summary_code		varchar(32)	NOT NULL,
		summary_type		tinyint	NOT NULL,
		bal_fwd_flag		smallint	NOT NULL,  
		balance_type		smallint	NOT NULL,
		seg1_code		varchar(32)	NOT NULL,
		seg2_code		varchar(32)	NOT NULL,
		seg3_code		varchar(32)	NOT NULL,
		seg4_code		varchar(32)	NOT NULL,
		account_type		smallint 	NOT NULL )

CREATE UNIQUE CLUSTERED	INDEX	#sumhdr_ind_0
ON     		#sumhdr ( summary_code, summary_type )

	


























































































CREATE TABLE	#acct  (	account_code	varchar(32) NOT NULL, 
				balance_type	smallint NOT NULL )

CREATE UNIQUE INDEX	#acct_ind_0
ON			#acct ( account_code, balance_type )


	

























































































CREATE TABLE	#updglbal (	
		account_code		varchar(32)	NOT NULL,
		currency_code		varchar(8)	NOT NULL,
		balance_date		int	NOT NULL,
		balance_until		int	NOT NULL,
		balance_type		smallint	NOT NULL,
		current_balance		float	NOT NULL,
		home_current_balance	float	NOT NULL,
		bal_fwd_flag		smallint	NOT NULL,  
		seg1_code		varchar(32)	NOT NULL,
		seg2_code		varchar(32)	NOT NULL,
		seg3_code		varchar(32)	NOT NULL,
		seg4_code		varchar(32)	NOT NULL,
                account_type            smallint        NOT NULL,
                current_balance_oper    float           NOT NULL)

CREATE UNIQUE INDEX #updglbal_ind_0
ON #updglbal (	account_code, 
		currency_code, 
		balance_date, 
		balance_type )

	


























































































CREATE TABLE	#drcr (
		account_code	varchar(32)	NOT NULL,	
		balance_type	smallint	NOT NULL,
		currency_code	varchar(8)	NOT NULL,
		home_debit	float	NOT NULL,
		home_credit	float	NOT NULL,
		nat_debit	float	NOT NULL,
		nat_credit	float	NOT NULL,
		bal_fwd_flag	smallint	NOT NULL,  
		seg1_code	varchar(32)	NOT NULL,
		seg2_code	varchar(32)	NOT NULL,
		seg3_code	varchar(32)	NOT NULL,
		seg4_code	varchar(32)	NOT NULL,
		account_type	smallint	NOT NULL,
                initialized     tinyint         NOT NULL,
                oper_debit      float           NOT NULL,
                oper_credit     float           NOT NULL )

CREATE UNIQUE INDEX #drcr_ind_0 
	ON #drcr ( account_code, currency_code, balance_type )


	






























































































CREATE TABLE #new_trx
(
        journal_ctrl_num	varchar(16)	NOT NULL,
        new_journal_ctrl_num	varchar(16)	NOT NULL,
	flag_type		smallint	NOT NULL
)


CREATE INDEX	#new_trx_ind_0
ON		  	#new_trx (	new_journal_ctrl_num, 
					journal_ctrl_num )

	


	WHILE 1=1
	BEGIN
		


		TRUNCATE TABLE	#hold
		TRUNCATE TABLE	#gldtrx
		TRUNCATE TABLE	#gldtrdet
		TRUNCATE TABLE	#summary
		TRUNCATE TABLE	#sumhdr
	     	TRUNCATE TABLE	#acct
		TRUNCATE TABLE	#updglbal
		TRUNCATE TABLE	#drcr
		TRUNCATE TABLE	#new_trx

		SELECT	@batch_code = NULL
		
		SELECT	@batch_code = MIN( batch_ctrl_num )
		FROM	batchctl
		WHERE	process_group_num = @process_ctrl_num
		AND	batch_type = 6010
		AND	posted_flag = -1
		
		IF ( @batch_code IS NULL )
			break
		


		EXEC	@result = glpsprep_sp	@batch_code, @debug
		IF ( @result != 0 )
		BEGIN
			EXEC	pctrlupd_sp	@process_ctrl_num,
						2
			SELECT	@error_flag = @result
			return @result
		END
		



		EXEC	@result = glpsechk_sp	@batch_code,
						@company_code,
						@company_code,
						@debug
		IF ( @result = 202 )
			SELECT	@errors_found = 1, @result = 0		
			
		ELSE IF ( @result != 0 )
		BEGIN
			EXEC	pctrlupd_sp	@process_ctrl_num,
						2
			SELECT	@error_flag = @result
			return @result
		END
		


		EXEC	@result = glpshold_sp	@batch_code,
						@debug
		IF ( @result != 0 )
		BEGIN
			EXEC	pctrlupd_sp	@process_ctrl_num,
						2
			SELECT	@error_flag = @result
			return @result
		END
		



		IF ( @errors_found = 1 AND @batch_mode_on = 1 )
		BEGIN
			EXEC	batupdst_sp	@batch_code,
						5
			CONTINUE
		END
			
		EXEC	@result = glpspost_sp	@batch_code,
						@debug
		IF ( @result != 0 )
		BEGIN
			EXEC	pctrlupd_sp	@process_ctrl_num,
						2
			SELECT	@error_flag = @result
			return @result
		END
			
	END

	EXEC	pctrlupd_sp	@process_ctrl_num,
				3

	EXEC	status_sp	"GLAPPSTD", 
				@process_id, 
				@user_id, 
				@str_msg, 
				100, 
				@orig_flag, 
				0

	DROP TABLE	#hold
	DROP TABLE	#gldtrx
	DROP TABLE	#gldtrdet
	DROP TABLE	#summary
	DROP TABLE	#sumhdr
	DROP TABLE	#acct
	DROP TABLE	#updglbal
	DROP TABLE	#drcr
	DROP TABLE	#new_trx

	RETURN	0
END

GO
GRANT EXECUTE ON  [dbo].[glappstd_sp] TO [public]
GO
