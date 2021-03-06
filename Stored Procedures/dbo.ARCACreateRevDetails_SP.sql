SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 
































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARCACreateRevDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									








IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arcacrd.cpp', 54, 'Entering ARCACreateRevDetails_SP', @PERF_time_last OUTPUT















BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacrd.cpp' + ', line ' + STR( 71, 5 ) + ' -- ENTRY: '

	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,				rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		reference_code,				org_id
	)

	SELECT	DISTINCT
		pyt.date_applied,			pdt.gl_acct_code,
		pyt.trx_desc,				pyt.customer_code,
		pyt.doc_ctrl_num,			pdt.extended_price,
		pyt.nat_cur_code,			pyt.rate_type_home,
		pyt.rate_type_oper,			pyt.rate_home,
		pyt.rate_oper,				pyt.trx_type,
		0,			pyt.trx_ctrl_num,
		pdt.reference_code,			pdt.org_id			
	FROM	#arinppyt_work pyt, #arnonardet_work pdt 
	WHERE	pyt.batch_code        = @batch_ctrl_num
	AND	pyt.trx_ctrl_num      = pdt.trx_ctrl_num
	AND	pyt.non_ar_flag       = 1
	AND     pdt.extended_price > 0





















	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arcacrd.cpp' + ', line ' + STR( 125, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

END

GO
GRANT EXECUTE ON  [dbo].[ARCACreateRevDetails_SP] TO [public]
GO
