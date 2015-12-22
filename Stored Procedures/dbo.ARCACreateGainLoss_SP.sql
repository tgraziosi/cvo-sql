SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 











































































































































































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCACreateGainLoss_SP]		@batch_ctrl_num     varchar( 16 ),
                                		@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcacgl.cpp', 52, 'Entering ARCACreateGainLoss_SP', @PERF_time_last OUTPUT

DECLARE
	@company_code	varchar(8)
	

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 59, 5 ) + ' -- ENTRY: ' 
	
	SELECT @company_code = company_code
	FROM	glco

	CREATE TABLE #g_l_accts
	(
		 nat_cur_code	varchar(8),
		 posting_code	varchar(8),
		 ar_acct_code	varchar(32),
		 gain_acct	varchar(32),
		 loss_acct	varchar(32)
	)

	INSERT	#g_l_accts
	SELECT	DISTINCT b.inv_cur_code, 
			a.posting_code, 
			dbo.IBAcctMask_fn(d.ar_acct_code,c.org_id), 
			'', ''
	FROM	#artrx_work a, #arinppdt_work b, #arinppyt_work c, araccts d
	WHERE	a.doc_ctrl_num = b.sub_apply_num
	AND	a.trx_type = b.sub_apply_type
	AND	b.trx_ctrl_num = c.trx_ctrl_num
	AND	c.batch_code = @batch_ctrl_num
	AND	a.posting_code = d.posting_code
	AND	(b.inv_cur_code != c.nat_cur_code
		OR SIGN(gain_home ) != 0
			OR SIGN(gain_oper) != 0 )


	IF @@rowcount != 0
	BEGIN

		SELECT	a.currency_code, b.ar_acct_code, sequence_id = MIN(a.sequence_id)
		INTO	#temp
		FROM	CVO_Control..mccocdt a, #g_l_accts b
		WHERE	a.company_code = @company_code
		AND	b.ar_acct_code like a.acct_mask
		AND	a.currency_code = b.nat_cur_code
		GROUP BY a.currency_code, b.ar_acct_code


		UPDATE	#g_l_accts
		SET	gain_acct = c.rea_gain_acct,
			loss_acct = c.rea_loss_acct
		FROM	#g_l_accts a, #temp b, CVO_Control..mccocdt c
		WHERE	a.nat_cur_code = b.currency_code
		AND	a.ar_acct_code = b.ar_acct_code
		AND	b.currency_code = c.currency_code
		AND	b.sequence_id = c.sequence_id
		AND	c.company_code = @company_code


		DROP TABLE #temp

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 117, 5 ) + ' -- MSG: ' + 'debit invoice amounts to gain accounts/2nd currency'

		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			org_id	
		)
		SELECT	pyt.date_applied,			acct.gain_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-pdt.inv_amt_applied,			
			trx.nat_cur_code,			trx.rate_type_home,			
			trx.rate_type_oper,			trx.rate_home,			
			trx.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pyt.org_id
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, #g_l_accts acct
		WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pdt.trx_type = pyt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 151, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 158, 5 ) + ' -- MSG: ' + 'debit invoice amounts to loss accounts/2nd currency'
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			org_id
		)
		SELECT	pyt.date_applied,			acct.loss_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-pdt.inv_amt_applied,			
			trx.nat_cur_code,			trx.rate_type_home,			
			trx.rate_type_oper,			trx.rate_home,			
			trx.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pyt.org_id
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, #g_l_accts acct
		WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pdt.trx_type = pyt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 191, 5 ) + ' -- EXIT: '
			RETURN 34563
		END


		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 199, 5 ) + ' -- MSG: ' + 'credit payment amounts to gain accounts/2nd currency'
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			org_id
		)
		SELECT	pyt.date_applied,			acct.gain_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			pdt.amt_applied,			
			pyt.nat_cur_code,			pyt.rate_type_home,			
			pyt.rate_type_oper,			pyt.rate_home,			
			pyt.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pyt.org_id
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, #g_l_accts acct
		WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pdt.trx_type = pyt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 232, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 239, 5 ) + ' -- MSG: ' + 'credit payment amounts to loss accounts/2nd currency'
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			org_id	
		)
		SELECT	pyt.date_applied,			acct.loss_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			pdt.amt_applied,			
			pyt.nat_cur_code,			pyt.rate_type_home,			
			pyt.rate_type_oper,			pyt.rate_home,			
			pyt.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pyt.org_id
		FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, #g_l_accts acct
		WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
		AND	pdt.trx_type = pyt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code != pdt.inv_cur_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 272, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 280, 5 ) + ' -- MSG: ' + 'debit payment amounts to gain accounts/1st currency'
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			home_balance,				oper_balance,
			org_id	
		)
		SELECT	pyt.date_applied,			acct.gain_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			0.0,			
			pyt.nat_cur_code,			pyt.rate_type_home,			
			pyt.rate_type_oper,			0.0,			
			0.0,					pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pdt.gain_home,			pdt.gain_oper,
			pyt.org_id
		FROM	#g_l_accts acct, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.trx_type = pdt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	pdt.gain_home >= 0.0
		AND	pyt.nat_cur_code = pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	( pdt.gain_home != 0.0 OR pdt.gain_oper != 0.0 )
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 316, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 323, 5 ) + ' -- MSG: ' + 'debit payment amounts to loss accounts/1st currency'
		INSERT	#argldist
		(
			date_applied,				account_code,		
			description,				document_1,
			document_2,				nat_balance,				
			nat_cur_code,				rate_type_home,			
			rate_type_oper,			rate_home,				
			rate_oper,				trx_type,				
			seq_ref_id,				trx_ctrl_num,
			home_balance,				oper_balance,
			org_id
		)
		SELECT	pyt.date_applied,			acct.loss_acct,	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			0.0,			
			pyt.nat_cur_code,			pyt.rate_type_home,			
			pyt.rate_type_oper,			0.0,			
			0.0,					pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			pdt.gain_home,			pdt.gain_oper,
			pyt.org_id
		FROM	#g_l_accts acct, #arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.trx_type = pdt.trx_type
		AND	pdt.sub_apply_num = trx.doc_ctrl_num
		AND	pdt.sub_apply_type = trx.trx_type
		AND	pdt.gain_home < 0.0
		AND	pyt.nat_cur_code = pdt.inv_cur_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	( pdt.gain_home != 0.0 OR pdt.gain_oper != 0.0 )
		AND	trx.nat_cur_code = acct.nat_cur_code
		AND	trx.posting_code = acct.posting_code

		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 359, 5 ) + ' -- EXIT: '
			RETURN 34563
		END


	END



DROP TABLE #g_l_accts


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacgl.cpp' + ', line ' + STR( 371, 5 ) + ' -- EXIT: '
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcacgl.cpp', 372, 'Leaving ARCACreateGainLoss_SP', @PERF_time_last OUTPUT
RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCACreateGainLoss_SP] TO [public]
GO
