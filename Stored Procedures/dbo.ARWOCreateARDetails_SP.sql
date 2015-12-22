SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


























  



					  

























































 
































































































































































































































































































































































































































































































































































CREATE PROC [dbo].[ARWOCreateARDetails_SP]	@batch_ctrl_num     varchar( 16 ),
                           		@debug_level        smallint = 0,
					@perf_level         smallint = 0    
AS

DECLARE	@journal_type		varchar(8),
		@company_code		varchar(8),
		@home_currency	varchar(8),
		@oper_currency	varchar(8)










BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocard.cpp' + ', line ' + STR( 64, 5 ) + ' -- ENTRY: '

	SELECT	@journal_type = journal_type
	FROM	glappid
	WHERE	app_id = 2000

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocard.cpp' + ', line ' + STR( 72, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	SELECT	@company_code = company_code,
		@home_currency = home_currency,
		@oper_currency = oper_currency
	FROM	glco

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocard.cpp' + ', line ' + STR( 83, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	IF( @debug_level >= 2 )
	BEGIN
		SELECT	'Rows in #argldist before insert for writeoff account'
		SELECT	'date_applied journal_type rec_company_code account code description document_1 document_2'
		SELECT	STR(date_applied, 7) + ':' +
				journal_type + ':' +
				rec_company_code + ':' +
				account_code + ':' +
				description + ':' +
				document_1 + ':' +
				document_2
		FROM	#argldist
				
		SELECT	'document_2 nat_balance nat_cur_code home_balance home_cur oper_bal oper_cur rate_h rate_o trx_type seq_ref_id'
		SELECT	document_2 + ':' +
				STR(nat_balance, 10, 4) + ':' +
				nat_cur_code + ':' +
				STR(home_balance, 10, 4) + ':' +
				home_cur_code + ':' +
				STR(oper_balance, 10, 4) + ':' +
				oper_cur_code + ':' +
				STR(rate_home, 10, 6) + ':' +
				STR(rate_oper, 10, 6) + ':' +
				STR(trx_type, 5 ) + ':' +
				STR(seq_ref_id, 6)
		FROM	#argldist
	END



	


	INSERT	#argldist
	(
		date_applied,						account_code,		description,
		document_1,						document_2,		reference_code,
		nat_balance,						nat_cur_code,		rate_home,
		trx_type,						seq_ref_id,		trx_ctrl_num,
		rate_oper,						rate_type_home,	rate_type_oper,	
		org_id
			)
	SELECT	pyt.date_applied,					dbo.IBAcctMask_fn(acct.ar_acct_code,trx.org_id),	pyt.trx_desc,	
		pdt.customer_code,					pdt.doc_ctrl_num,	' ',
		(-1) * (pdt.inv_amt_applied),	trx.nat_cur_code,	trx.rate_home, 
		pdt.trx_type,						0,			pdt.trx_ctrl_num,
		trx.rate_oper,					trx.rate_type_home,	trx.rate_type_oper,
		trx.org_id									
	FROM	#arinppdt_work pdt, #artrx_work trx, araccts acct, #arinppyt_work pyt
	WHERE	pdt.apply_to_num = trx.doc_ctrl_num
	AND	pdt.apply_trx_type = trx.trx_type
	AND	pdt.trx_ctrl_num = pyt.trx_ctrl_num
	AND	pdt.trx_type = pyt.trx_type
	AND	trx.posting_code = acct.posting_code
	AND	pyt.batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocard.cpp' + ', line ' + STR( 144, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	IF( @debug_level >= 2 )
	BEGIN
		SELECT	'Rows in #argldist before insert for writeoff account'
		SELECT	'date_applied journal_type rec_company_code account code description document_1 document_2'
		SELECT	STR(date_applied, 7) + ':' +
				journal_type + ':' +
				rec_company_code + ':' +
				account_code + ':' +
				description + ':' +
				document_1 + ':' +
				document_2
		FROM	#argldist
				
		SELECT	'document_2 nat_balance nat_cur_code home_balance home_cur oper_bal oper_cur rate_h rate_o trx_type seq_ref_id'
		SELECT	document_2 + ':' +
				STR(nat_balance, 10, 4) + ':' +
				nat_cur_code + ':' +
				STR(home_balance, 10, 4) + ':' +
				home_cur_code + ':' +
				STR(oper_balance, 10, 4) + ':' +
				oper_cur_code + ':' +
				STR(rate_home, 10, 6) + ':' +
				STR(rate_oper, 10, 6) + ':' +
				STR(trx_type, 5 ) + ':' +
				STR(seq_ref_id, 6)
		FROM	#argldist
	END



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arwocard.cpp' + ', line ' + STR( 177, 5 ) + ' -- EXIT: '

END

GO
GRANT EXECUTE ON  [dbo].[ARWOCreateARDetails_SP] TO [public]
GO
