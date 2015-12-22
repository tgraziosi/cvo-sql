SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO






















































































































































































































































































































































































































CREATE PROC  [dbo].[ARCMCreateOnAccountPayments_SP]	@batch_ctrl_num	varchar( 16 ),
							@debug_level		smallint = 0,
							@perf_level		smallint = 0
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									
























DECLARE
	@result 		int,
	@process_ctrl_num	varchar(16),
	@user_id		smallint,
	@date_entered		int,
	@period_end		int,
	@batch_type		smallint

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcmcoap.cpp', 68, 'Entering ARCMCreateOnAccountPayments_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 71, 5 ) + ' -- ENTRY: '

	EXEC @result = batinfo_sp	@batch_ctrl_num,
					@process_ctrl_num OUTPUT,
					@user_id OUTPUT,
					@date_entered OUTPUT, 
					@period_end OUTPUT,
					@batch_type OUTPUT
	IF( @result != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 81, 5 ) + ' -- EXIT: '
		RETURN 35011
	END


	


	
CREATE TABLE	#arnumblk
(
	num_type		int			NOT NULL,
	get_num			int			NOT NULL,
	char16_ref1		varchar(16)	NULL,
	char16_ref2		varchar(16)	NULL,
	char8_ref1		varchar(8)	NULL,
	char8_ref2		varchar(8)	NULL,
	int_ref1		int			NULL,
	int_ref2		int			NULL,
	smallint_ref1	smallint	NULL,
	smallint_ref2	smallint	NULL,
	masked			varchar(35)	NULL,
	num				int			NULL,
	sequence_key	int			NULL
)

	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 91, 5 ) + ' -- MSG: ' + 'Inserting #arnumblk'
	INSERT	#arnumblk
	(
		num_type,				get_num,				masked,
		char16_ref1,				char8_ref1,				smallint_ref1
	)
	SELECT	2010,			1,					cr_trx_ctrl_num,
		trx_ctrl_num,				' ',					2111
	FROM	#arcmcr
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 102, 5 ) + ' -- EXIT: '
        	RETURN 34563
	END
	
	IF EXISTS(SELECT num_type FROM #arnumblk)
	BEGIN
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 108, 5 ) + ' -- MSG: ' + 'Calling ARGetNumberBlock_SP'
		EXEC @result = ARGetNumberBlock_SP	@process_ctrl_num,
							@debug_level

		IF ( @debug_level > 0 )
		BEGIN
			SELECT 'num_type = ' + STR(num_type) +
				'char16_ref1 = ' + char16_ref1 +
				'masked = ' + masked
			FROM	#arnumblk
		END
		
		IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 120, 5 ) + ' -- MSG: ' + 'Updating #arcmcr.cr_trx_ctrl_num'
		UPDATE #arcmcr
		SET	cr_trx_ctrl_num = #arnumblk.masked
		FROM	#arnumblk
		WHERE	#arcmcr.trx_ctrl_num = #arnumblk.char16_ref1
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 127, 5 ) + ' -- EXIT: '
	        	RETURN 34563
		END
		
	END				
	
	DROP TABLE #arnumblk

	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 135, 5 ) + ' -- MSG: ' + 'Inserting #arinppyt'
	INSERT  #arinppyt
	(
		trx_ctrl_num,			doc_ctrl_num,		trx_desc,
		batch_code,    		trx_type,		non_ar_flag,
		non_ar_doc_num,		gl_acct_code,		date_entered,
		date_applied,			date_doc,    		customer_code,
		payment_code,			payment_type,		amt_payment,
		amt_on_acct,			prompt1_inp,		prompt2_inp,
		prompt3_inp,			prompt4_inp,		deposit_num,
		bal_fwd_flag,			printed_flag,		posted_flag,
		hold_flag,			wr_off_flag,		on_acct_flag,
		user_id,			max_wr_off, 		days_past_due,   
		void_type,  			cash_acct_code,    	origin_module_flag, 
	 	process_group_num,		trx_state,		mark_flag,
		source_trx_ctrl_num,		source_trx_type,	nat_cur_code,
		rate_type_home,		rate_type_oper,	rate_home,
		rate_oper,			reference_code,	org_id
	)       
	SELECT 
		cr.cr_trx_ctrl_num,		chg.doc_ctrl_num,	chg.doc_desc,
		'',    			2111,	0,
		'',				'',			@date_entered,
		chg.date_applied,		chg.date_doc,    	chg.customer_code,
		'',				3,			cr.amt_net,
		cr.amt_on_acct,		'',			'',
		'',				'',			'',
		0,				0,			-1,
		0,				0,			cr.on_acct_flag,
		@user_id,			0, 			0,   
		0,  				'',    		0, 
	 	@process_ctrl_num,		0,		0,
		cr.trx_ctrl_num,		2032,	chg.nat_cur_code,
		chg.rate_type_home,		chg.rate_type_oper,	chg.rate_home,
		chg.rate_oper,		'',		chg.org_id
      	FROM	#arcmcr cr, #arinpchg_work chg
	WHERE	cr.trx_ctrl_num = chg.trx_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 174, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 178, 5 ) + ' -- MSG: ' + 'Inserting #arinppdt'
	INSERT  #arinppdt	
	(	
		trx_ctrl_num,	     		doc_ctrl_num,		 sequence_id,
		trx_type,			apply_to_num,		 apply_trx_type,
		customer_code,		date_aging,		 amt_applied,
		amt_disc_taken,		wr_off_flag,		 amt_max_wr_off,
		void_flag,			line_desc,		 sub_apply_num,
		sub_apply_type,		amt_tot_chg,		 amt_paid_to_date,
		terms_code,			posting_code,		 date_doc, 
		amt_inv,			gain_home,		 gain_oper,
		inv_amt_applied,		inv_amt_disc_taken,	 inv_amt_max_wr_off,		
	      	inv_cur_code,			trx_state,		 mark_flag, org_id
	)
	SELECT	cr.cr_trx_ctrl_num,	     	doc_ctrl_num,		 1,
		2111,				cr.apply_to_num,	 cr.apply_trx_type,
		customer_code,		cr.date_aging,	 amt_applied,
		0.0,		    		0,		 	0.0,
		0,				chg.doc_desc,		 '',
		0,				0.0,		 	0.0,
		'',				'',		 	0, 
		0.0,				0.0,		 	0.0,
		amt_applied,			0.0,	 		0.0,		
	      	nat_cur_code,			0,		 0, chg.org_id
	FROM	#arcmcr cr, #arinpchg_work chg
	WHERE	cr.trx_ctrl_num = chg.trx_ctrl_num
	AND	(ABS((cr.amt_applied)-(0.0)) > 0.0000001)
	AND	cr.apply_trx_type != 0
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 208, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	IF ( @debug_level > 0 )
	BEGIN
		SELECT 'Dumping #arinppdt...'
		SELECT 'trx_ctrl_num = ' + trx_ctrl_num +
			'apply_to_num = ' + apply_to_num +
			'amt_applied = ' + STR(amt_applied, 10, 2)
		FROM	#arinppdt
	END
		
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcmcoap.cpp', 221, 'Leaving ARCMCreateOnAccountPayments_SP', @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcmcoap.cpp' + ', line ' + STR( 222, 5 ) + ' -- EXIT: '
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateOnAccountPayments_SP] TO [public]
GO
