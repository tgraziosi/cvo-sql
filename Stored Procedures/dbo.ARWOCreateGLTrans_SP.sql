SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOCreateGLTrans_SP]	@batch_ctrl_num     varchar( 16 ),
                                	@debug_level        smallint = 0,
                                	@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
    @result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arwocglt.cpp', 46, 'Entering ARWOCreateGLTrans_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 49, 5 ) + ' -- ENTRY: '

	








	


	
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


	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 67, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


	EXEC @result = ARWOCreateARDetails_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 80, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	EXEC @result = ARWOCreateWROffdetails_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 94, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	


	EXEC @result = ARLoadHomeOper_SP	@debug_level,
						@perf_level

	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 106, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	




	UPDATE #argldist
	SET	journal_description = p.process_description
	FROM	pcontrol_vw p, batchctl b
	WHERE	b.batch_ctrl_num = @batch_ctrl_num
	AND	b.process_group_num = p.process_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 123, 5 ) + ' -- EXIT: '
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
				
		SELECT	'document_2 reference_code home_balance home_cur_code nat_balance nat_cur_code rate_home trx_type seq_ref_id'
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

		SELECT 'rate_type_home rate_type_oper oper_balance oper_cur_code rate_oper'
		SELECT rate_type_home + ':' +
			rate_type_oper + ':' +
			STR(oper_balance, 10, 4) + ':' +
			oper_cur_code + ':' +
			STR(rate_oper, 10, 6 )
		FROM	#argldist
	END

	


	EXEC @result = ARCreateGLTransactions_SP	@batch_ctrl_num,
							@debug_level,
							@perf_level
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 169, 5 ) + ' -- EXIT: '
		RETURN @result
	END
	



	INSERT	#arwotemp ( trx_ctrl_num, trx_type, journal_ctrl_num)
	SELECT	trx_ctrl_num,
		trx_type,
		' '
	FROM	#arinppyt_work
	WHERE	batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocglt.cpp' + ', line ' + STR( 185, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	




	UPDATE	#arwotemp
	SET	journal_ctrl_num = argl.journal_ctrl_num
	FROM	#argldist argl, #arwotemp tmp
	WHERE	argl.trx_ctrl_num = tmp.trx_ctrl_num
	AND	argl.trx_type = tmp.trx_type

	



	DROP TABLE #argldist

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arwocglt.cpp', 206, 'Leaving ARWOCreateGLTransactions_SP', @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARWOCreateGLTrans_SP] TO [public]
GO
