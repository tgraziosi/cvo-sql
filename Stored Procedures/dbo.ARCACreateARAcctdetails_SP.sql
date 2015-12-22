SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* End mod: CB0001 */











 



					 










































 






















































































































































































































































































































































































































































































































 
















































































CREATE PROC [dbo].[ARCACreateARAcctdetails_SP]	@batch_ctrl_num varchar( 16 ),
 		@debug_level smallint = 0,
 		@perf_level smallint = 0 
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									








IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'tmp/arcacara.sp', 47, 'Entering ARCACreateARAcctdetails_SP', @PERF_time_last OUTPUT



BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacara.sp' + ', line ' + STR( 58, 5 ) + ' -- ENTRY: '


	
	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num	,
		org_id
	)
	SELECT	pyt.date_applied,			dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id),		
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			pdt.inv_amt_applied + pdt.inv_amt_disc_taken + pdt.inv_amt_max_wr_off,			
		trx.nat_cur_code,			trx.rate_type_home,			
		trx.rate_type_oper,			trx.rate_home,			
		trx.rate_oper,			pyt.trx_type,				
		0,					pyt.trx_ctrl_num,
		trx.org_id							
	FROM	#arinppdt_work pdt, #arinppyt_work pyt, #artrx_work trx, araccts acct
	WHERE	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pdt.sub_apply_num = trx.doc_ctrl_num
	AND	pdt.sub_apply_type = trx.trx_type
	AND	trx.posting_code = acct.posting_code
	AND	pyt.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacara.sp' + ', line ' + STR( 90, 5 ) + ' -- EXIT: '
		RETURN 34563
	END


	IF ( EXISTS(SELECT 1 from arco with (nolock) where chargeback_flag = 1 ))
	BEGIN
		/* Begin mod: CB0001 - Add credit entry to the AR account for chargebacks - The Emerald Group - Chargebacks */	
	
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
		SELECT	pyt.date_applied,			dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id),	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-cb.amount,			
			trx.nat_cur_code,			trx.rate_type_home,			
			trx.rate_type_oper,			trx.rate_home,			
			trx.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			trx.org_id							
		FROM	artrxage cb, #arinppyt_work pyt, araccts acct, artrx chk, artrx trx
		WHERE	chk.doc_ctrl_num = pyt.doc_ctrl_num 
		AND	chk.trx_type = 2111
		AND	chk.customer_code = pyt.customer_code
		AND	trx.prompt1_inp = chk.trx_ctrl_num
		AND	trx.trx_ctrl_num = cb.trx_ctrl_num
		AND	(cb.trx_type = 2031 OR (cb.trx_type = 2161 and cb.doc_ctrl_num like 'CA%'))
		AND	pyt.batch_code = @batch_ctrl_num
		AND	trx.posting_code = acct.posting_code
		AND	pyt.trx_type between 2113 and 2121
		AND	cb.trx_ctrl_num NOT IN
		(SELECT	trx_ctrl_num FROM artrxage WHERE trx_ctrl_num = cb.trx_ctrl_num AND trx_type = 2111)

	
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacara.sp' + ', line ' + STR( 91, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		/* End mod: CB0001 */

		/* Begin mod: CB0001 - Add credit entry to the AR account for credit memos on check 	 */
	
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
		SELECT	pyt.date_applied,			dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id),	
			pyt.trx_desc,				pyt.customer_code,
			pyt.doc_ctrl_num,			-cb.amount,			
			trx.nat_cur_code,			trx.rate_type_home,			
			trx.rate_type_oper,			trx.rate_home,			
			trx.rate_oper,			pyt.trx_type,				
			0,					pyt.trx_ctrl_num,
			trx.org_id							
		FROM	artrxage cb, #arinppyt_work pyt, araccts acct, artrx trx
		WHERE	cb.doc_ctrl_num = pyt.doc_ctrl_num 
		AND	cb.trx_type = 2111
		AND	cb.apply_trx_type = 2161
		AND	cb.ref_id = -1
		AND	cb.payer_cust_code = pyt.customer_code
		AND	pyt.batch_code = @batch_ctrl_num
		AND	trx.doc_ctrl_num = cb.apply_to_num
		AND	trx.trx_type = 2032
		AND	trx.posting_code = acct.posting_code
		AND	pyt.trx_type between 2113 and 2121
		

	
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacara.sp' + ', line ' + STR( 92, 5 ) + ' -- EXIT: '
			RETURN 34563
		END

		/* End mod: CB0001 */
	END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/arcacara.sp' + ', line ' + STR( 94, 5 ) + ' -- EXIT: '
IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'tmp/arcacara.sp', 95, 'Leaving ARCACreateARAcctdetails_SP', @PERF_time_last OUTPUT
RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARCACreateARAcctdetails_SP] TO [public]
GO
