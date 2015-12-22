SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateFreightDetails_SP]	@batch_ctrl_num     varchar( 16 ),
						@debug_level        smallint = 0,
						@perf_level         smallint = 0    
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcfd.cpp", 81, "Entering ARCMCreateFreightDetails_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcfd.cpp" + ", line " + STR( 84, 5 ) + " -- ENTRY: "

	CREATE TABLE	#amt_freight
	(
		trx_ctrl_num	varchar(16),
		trx_type	smallint,
		amt_freight	float
	)
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcfd.cpp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	





	INSERT	#amt_freight
	(
		trx_ctrl_num,
		trx_type,
		amt_freight
	)
	SELECT	arinpchg.trx_ctrl_num,
		arinpchg.trx_type,
		arinpchg.amt_freight
	FROM	#arinpchg_work arinpchg, artax
	WHERE	arinpchg.tax_code = artax.tax_code
	AND	arinpchg.recurring_flag != 2
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_freight
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcfd.cpp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	



























	



























	



	INSERT	#argldist
	(
		date_applied,			account_code,                   description,                        
		document_1,			document_2,			nat_balance,
		nat_cur_code,			rate_home,			trx_type,
		seq_ref_id,			trx_ctrl_num,			rate_type_home,
		rate_type_oper,		        rate_oper,                      org_id        
	)
	SELECT	arinpchg.date_applied,	dbo.IBAcctMask_fn(acct.freight_acct_code,arinpchg.org_id),	arinpchg.doc_desc,
		arinpchg.customer_code,	arinpchg.doc_ctrl_num,	amt.amt_freight,
		arinpchg.nat_cur_code,	rate_home,		arinpchg.trx_type,
		0,			arinpchg.trx_ctrl_num,	rate_type_home,
		rate_type_oper,		rate_oper,              arinpchg.org_id       
	FROM	#arinpchg_work arinpchg, araccts acct, #amt_freight amt
	WHERE	arinpchg.batch_code = @batch_ctrl_num
	AND	arinpchg.posting_code = acct.posting_code
	AND	arinpchg.trx_ctrl_num = amt.trx_ctrl_num
	AND	arinpchg.trx_type = amt.trx_type
	IF( @@error != 0 )
	BEGIN
		DROP TABLE #amt_freight
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcfd.cpp" + ", line " + STR( 204, 5 ) + " -- EXIT: "
	RETURN 34563
	END

	DROP TABLE #amt_freight
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmcfd.cpp" + ", line " + STR( 211, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmcfd.cpp", 215, "Leaving ARCMCreateFreightDetails_SP", @PERF_time_last OUTPUT
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateFreightDetails_SP] TO [public]
GO
