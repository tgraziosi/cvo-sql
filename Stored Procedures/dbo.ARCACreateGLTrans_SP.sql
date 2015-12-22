SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 
































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCACreateGLTrans_SP]	@batch_ctrl_num	varchar( 16 ),
					@debug_level		smallint = 0,
					@perf_level		smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcacglt.cpp', 49, 'Entering ARCACreateGLTrans_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 52, 5 ) + ' -- ENTRY: '

	







	
CREATE TABLE	#argldist
(
	date_applied		int,
	journal_type		varchar(8)	NULL,
	rec_company_code	varchar(8)	NULL,
	account_code		varchar(32),
	description		varchar(40),
	document_1		varchar(16),
	document_2		varchar(16),
	reference_code	varchar(32)	NULL,
	home_balance		float		NULL,
	oper_balance		float		NULL,
	nat_balance		float,
	nat_cur_code		varchar(8),
	home_cur_code		varchar(8)	NULL,
	oper_cur_code		varchar(8)	NULL,
	rate_type_home	varchar(8),
	rate_type_oper	varchar(8),
	rate_home		float,
	rate_oper		float,
	trx_type		smallint,
	seq_ref_id		int,
	journal_ctrl_num	varchar(16)	NULL,
	journal_description	varchar(40)	NULL,
	trx_ctrl_num		varchar(16),
	gl_identity_value	smallint	NULL,
	org_id			varchar(30)	NULL
)


	


	IF EXISTS	(	
			SELECT	*
			FROM	#arinppyt_work
			WHERE	non_ar_flag = 1
			AND	batch_code = @batch_ctrl_num
			)
	BEGIN
		EXEC @result = ARCACreateRevDetails_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 79, 5 ) + ' -- EXIT: '
			RETURN @result
		END
	END

	



	EXEC @result = ARCACreateCashDetails_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 93, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARCACreateOnAccountDetails_SP	@batch_ctrl_num,
								@debug_level,
								@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 106, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARCAcreateOACMdetails_SP	@batch_ctrl_num,
								 	  			@debug_level,
								   				@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 119, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARCACreateARAcctdetails_SP	@batch_ctrl_num,
								 	  			@debug_level,
								   				@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 132, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARCACreateDiscTDetails_SP	@batch_ctrl_num,
								 	  			@debug_level,
								   				@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 145, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARCACreateWROffdetails_SP	@batch_ctrl_num,
								 	  			@debug_level,
								   				@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 158, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	


	EXEC @result = ARCACreateGainLoss_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 170, 5 ) + ' -- EXIT: '
		RETURN @result
	END



	


	IF EXISTS	(	
			SELECT	*
			FROM	#arinppyt_work
			WHERE	non_ar_flag = 1
			AND	batch_code = @batch_ctrl_num
			)
	BEGIN

		EXEC @result = ARCACreateTaxDetails_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
		IF( @result != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 192, 5 ) + ' -- EXIT: '
			RETURN @result
		END
	END



	




	UPDATE #argldist
	SET	journal_description = p.process_description
	FROM	pcontrol_vw p, batchctl b
	WHERE	b.batch_ctrl_num = @batch_ctrl_num
	AND	b.process_group_num = p.process_ctrl_num

	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 212, 5 ) + ' -- EXIT: '
			RETURN 34563
		END
	
	IF( @debug_level >= 2 )
	BEGIN
		SELECT	'Rows in #argldist before rounding'
		SELECT	'date_applied journal_type rec_company_code account code journal_description document_1 document_2'
		SELECT	STR(date_applied, 7) + ':' +
			journal_type + ':' +
			rec_company_code + ':' +
			account_code + ':' +
			journal_description + ':' +
			document_1 + ':' +
			document_2
		FROM	#argldist
				
		SELECT	'document_2 reference_code home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id'
		SELECT	document_2 + ':' +
			reference_code + ':' +
			STR(home_balance, 10, 4) + ':' +
			home_cur_code + ':' +
			STR(nat_balance, 10, 4) + ':' +
			nat_cur_code + ':' +
			STR(rate_home, 10, 6) + ':' +
			STR(trx_type, 5 ) + ':' +
			STR(seq_ref_id, 6)
		FROM	#argldist
	END


	



	EXEC @result = ARLoadHomeOper_SP	@debug_level,
						@perf_level

	


	EXEC @result = ARCreateGLTransactions_SP	@batch_ctrl_num,
												@debug_level,
												@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 258, 5 ) + ' -- EXIT: '
		RETURN @result
	END
	



	INSERT	#arcatemp( trx_ctrl_num, trx_type, journal_ctrl_num)
	SELECT	trx_ctrl_num,
		trx_type,
		' '
	FROM	#arinppyt_work
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacglt.cpp' + ', line ' + STR( 273, 5 ) + ' -- EXIT: '
		RETURN 34563
	END





	UPDATE	#arcatemp
	SET	journal_ctrl_num = argl.journal_ctrl_num
	FROM	#argldist argl, #arcatemp tmp
	WHERE	argl.trx_ctrl_num = tmp.trx_ctrl_num
	AND	argl.trx_type = tmp.trx_type

	



	DROP TABLE #argldist


	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcacglt.cpp', 295, 'Leaving ARCACreateGLTransactions_SP', @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCACreateGLTrans_SP] TO [public]
GO
