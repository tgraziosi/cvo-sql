SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARWOCreateWROffdetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
                                		@perf_level         smallint = 0    
AS

DECLARE	@journal_type		varchar(8),
		@company_code		varchar(8),
		@home_currency 	varchar(8),
		@oper_currency 	varchar(8),
		@rate			float,
		@precision		smallint













BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocwro.cpp' + ', line ' + STR( 70, 5 ) + ' -- ENTRY: '

	


	INSERT	#argldist
	(
		date_applied,					account_code,			description,
		document_1,					document_2,			reference_code,
		nat_balance,					nat_cur_code,			rate_home,
		trx_type,					seq_ref_id,			trx_ctrl_num,
		rate_oper,					rate_type_home,		rate_type_oper,
		org_id	
	)
	SELECT pyt.date_applied,				dbo.IBAcctMask_fn(arwo.writeoff_account,trx.org_id),	pyt.trx_desc,		
		pdt.customer_code,				pdt.doc_ctrl_num,		' ',
		pdt.inv_amt_applied,	trx.nat_cur_code,		trx.rate_home, 
		2151,				0,				pdt.trx_ctrl_num,
		trx.rate_oper,				trx.rate_type_home,		trx.rate_type_oper,
		trx.org_id												
	FROM	#arinppdt_work pdt, #artrx_work trx, arwrofac arwo, #arinppyt_work pyt
	WHERE	pdt.apply_to_num = trx.doc_ctrl_num
	AND	pdt.apply_trx_type = trx.trx_type
	AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pdt.trx_type = pyt.trx_type
	AND	pdt.writeoff_code = arwo.writeoff_code
	AND	pyt.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocwro.cpp' + ', line ' + STR( 100, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocwro.cpp' + ', line ' + STR( 104, 5 ) + ' -- EXIT: '
	RETURN 0 

END

GO
GRANT EXECUTE ON  [dbo].[ARWOCreateWROffdetails_SP] TO [public]
GO
