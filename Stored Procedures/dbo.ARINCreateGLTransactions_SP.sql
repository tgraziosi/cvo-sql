SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINCreateGLTransactions_SP]	@batch_ctrl_num	varchar(16),
						@journal_ctrl_num	varchar(16)	OUTPUT,
                                		@debug_level		smallint = 0,
                                		@perf_level		smallint = 0     
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







DECLARE
	@result		int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arincglt.cpp', 67, 'Entering ARINCreateGLTransactions_SP', @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 70, 5 ) + ' -- ENTRY: '


	








	
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


	


	INSERT	#argldist
	(
		date_applied,				account_code,
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,				rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		org_id	
	)
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(pc.ar_acct_code,chg.org_id),  
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			chg.amt_net,				
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,				chg.trx_type,				
		0,					chg.trx_ctrl_num,
		chg.org_id
	FROM	araccts pc, #arinpchg_work chg
	WHERE	pc.posting_code = chg.posting_code
	AND	chg.batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 111, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


		
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
	SELECT	chg.date_applied,			cdt.gl_rev_acct,	
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			-(cdt.extended_price + cdt.discount_amt-(tax.tax_included_flag * cdt.calc_tax)),			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,				chg.trx_type,				
		cdt.sequence_id,			chg.trx_ctrl_num,
		cdt.reference_code,			cdt.org_id
	FROM	#arinpchg_work chg, #arinpcdt_work cdt, artax tax
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	chg.trx_type = cdt.trx_type
	AND	cdt.tax_code = tax.tax_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 145, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	


	INSERT	#argldist
	(
		date_applied,				account_code,		
		description,				document_1,
		document_2,				nat_balance,				
		nat_cur_code,				rate_type_home,			
		rate_type_oper,			rate_home,				
		rate_oper,				trx_type,				
		seq_ref_id,				trx_ctrl_num,
		reference_code,				org_id	
	)
	SELECT	chg.date_applied,			rev.rev_acct_code,	
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			-rev.apply_amt,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		rev.sequence_id,			chg.trx_ctrl_num,
		rev.reference_code,			rev.org_id
	FROM	#arinpchg_work chg, #arinprev_work rev
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = rev.trx_ctrl_num
	AND	chg.trx_type = rev.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 177, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(typ.sales_tax_acct_code,chg.org_id),
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			-tax.amt_final_tax,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		tax.sequence_id,			chg.trx_ctrl_num,
		chg.org_id
	FROM	#arinpchg_work chg, #arinptax_work tax, artxtype typ
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = tax.trx_ctrl_num
	AND	chg.trx_type = tax.trx_type
	AND	tax.tax_type_code = typ.tax_type_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 210, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	


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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(accts.freight_acct_code,chg.org_id),
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			-chg.amt_freight,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num,
		chg.org_id
	FROM	#arinpchg_work chg, araccts	accts
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.posting_code = accts.posting_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 241, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	





	CREATE TABLE	#total_discount
	(
		trx_ctrl_num	varchar( 16 ),
		trx_type	smallint,
		discount_amt	float
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 259, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	INSERT	#total_discount
	(
		trx_ctrl_num, trx_type, discount_amt
	)
	SELECT	arinpchg.trx_ctrl_num, arinpchg.trx_type,	SUM(arinpcdt.discount_amt)
	FROM	#arinpchg_work arinpchg, #arinpcdt_work arinpcdt
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.trx_ctrl_num = arinpcdt.trx_ctrl_num
	AND	arinpchg.trx_type = arinpcdt.trx_type
	GROUP BY arinpchg.trx_ctrl_num, arinpchg.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 275, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(accts.disc_given_acct_code,chg.org_id),
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			disc.discount_amt,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num,
		chg.org_id
	FROM	#arinpchg_work chg, araccts accts, #total_discount disc
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = disc.trx_ctrl_num
	AND	chg.trx_type = disc.trx_type
	AND	chg.posting_code = accts.posting_code
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 305, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	DROP TABLE #total_discount

	


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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(accts.disc_given_acct_code,chg.org_id),
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			chg.amt_discount,				
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num,
		chg.org_id
	FROM	#arinpchg_work chg, araccts	accts
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.posting_code = accts.posting_code
	AND	chg.trx_type = 2021
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 339, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
	
	






	CREATE TABLE #cdt_tax_sums
	(
		trx_ctrl_num	varchar(16),
		amt_tax_included	float
	)

	INSERT	#cdt_tax_sums
	SELECT	chg.trx_ctrl_num,
		SUM(cdt.calc_tax)
	FROM	#arinpchg_work chg, #arinpcdt_work cdt, artax tax
	WHERE	chg.batch_code = @batch_ctrl_num
	AND	chg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	cdt.tax_code = tax.tax_code
	AND	tax.tax_included_flag = 1
	GROUP BY chg.trx_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 368, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
		
	


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
	SELECT	chg.date_applied,			dbo.IBAcctMask_fn(acct.tax_rounding_acct_code,chg.org_id),
		chg.doc_desc,				chg.customer_code,
		chg.doc_ctrl_num,			chg.amt_tax_included - cdt.amt_tax_included,			
		chg.nat_cur_code,			chg.rate_type_home,			
		chg.rate_type_oper,			chg.rate_home,			
		chg.rate_oper,			chg.trx_type,				
		0,					chg.trx_ctrl_num,
		chg.org_id
	FROM	#arinpchg_work chg, #cdt_tax_sums cdt, glcurr_vw gl, araccts acct
	WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
	AND	chg.nat_cur_code = gl.currency_code
	AND	chg.posting_code = acct.posting_code
	AND	ABS(ROUND(chg.amt_tax_included - cdt.amt_tax_included, gl.curr_precision)) >= gl.rounding_factor	
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 402, 5 ) + ' -- EXIT: '
		RETURN 34563
	END
		
	DROP TABLE #cdt_tax_sums

	



	UPDATE	#argldist
	SET	journal_description = p.process_description
	FROM	pcontrol_vw p, batchctl b
	WHERE	b.batch_ctrl_num = @batch_ctrl_num
	AND	b.process_group_num = p.process_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 420, 5 ) + ' -- EXIT: '
		RETURN 34563
	END

	IF( @debug_level >= 2 )
	BEGIN
		SELECT	'Rows in #argldist before rounding'
		SELECT	'date_applied journal_type rec_company_code account code description document_1 document_2'
		SELECT	STR(date_applied, 7) + ':' +
				journal_type + ':' +
				rec_company_code + ':' +
				account_code + ':' +
				description + ':' +
				document_1 + ':' +
				document_2
		FROM	#argldist
				
		SELECT	'org_id document_2 home_balance home_cur_code nat_balance nat_cur_code rate trx_type seq_ref_id'
		SELECT	document_2 + ':' +
				STR(home_balance, 10, 4) + ':' +
				home_cur_code + ':' +
				STR(nat_balance, 10, 4) + ':' +
				nat_cur_code + ':' +
				STR(rate_home, 10, 6) + ':' +
				STR(rate_oper, 10, 6) + ':' +
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
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'arincglt.cpp' + ', line ' + STR( 464, 5 ) + ' -- EXIT: '
		RETURN @result
	END

	



	SELECT	@journal_ctrl_num = ISNULL(MIN(journal_ctrl_num), ' ')
	FROM	#argldist
	
	



	DROP TABLE #argldist


	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, 'arincglt.cpp', 482, 'Leaving ARINCreateGLTransactions_SP', @PERF_time_last OUTPUT
	RETURN 0 

END
GO
GRANT EXECUTE ON  [dbo].[ARINCreateGLTransactions_SP] TO [public]
GO
