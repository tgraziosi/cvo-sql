SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC  [dbo].[ARCMUpdateInvoiceQuantities_SP]	@batch_ctrl_num	varchar( 16 ),
							@debug_level		smallint,
							@perf_level		smallint
AS








DECLARE
        @PERF_time_last     datetime

SELECT  @PERF_time_last = GETDATE()

















									







IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmuiq.cpp", 54, "Entering ARCMUpdateInvoiceQuantities_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmuiq.cpp" + ", line " + STR( 57, 5 ) + " -- ENTRY: "

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"qty_returned from #artrxcdt_work before update"
		SELECT	trx_ctrl_num + ":" +
				STR(qty_returned, 10, 4)
		FROM	#artrxcdt_work
	END

	CREATE TABLE	#arqty_returned
	(
		apply_to_num		varchar(16),
		apply_trx_type	smallint,
		item_code		varchar(30),
		qty_returned		float
	)		

	INSERT	#arqty_returned 
	SELECT	inpchg.apply_to_num,
		inpchg.apply_trx_type,
		inpcdt.item_code,
		SUM(inpcdt.qty_returned)
	FROM	#arinpchg_work inpchg, #arinpcdt_work inpcdt	
	WHERE	inpchg.batch_code = @batch_ctrl_num
	AND	inpchg.recurring_flag = 1
	AND	inpchg.trx_ctrl_num = inpcdt.trx_ctrl_num
	AND	inpchg.trx_type = inpcdt.trx_type
	AND	inpchg.apply_trx_type > 0
	AND	( LTRIM(inpcdt.item_code) IS NOT NULL AND LTRIM(inpcdt.item_code) != " " )
	GROUP BY inpchg.apply_to_num, inpchg.apply_trx_type, inpcdt.item_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmuiq.cpp" + ", line " + STR( 91, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	CREATE TABLE #min_seq_id
	(
		doc_ctrl_num		varchar(16),
		trx_type		smallint,
		item_code		varchar(30),
		sequence_id		int
	)		

	INSERT	#min_seq_id
	SELECT	trx.doc_ctrl_num, trx.trx_type, 
		cdt.item_code, MIN(cdt.sequence_id)
	FROM	#arqty_returned ret, #artrx_work trx, #artrxcdt_work cdt	 
	WHERE	ret.apply_to_num = trx.doc_ctrl_num
	AND	ret.apply_trx_type = trx.trx_type
	AND	trx.trx_ctrl_num = cdt.trx_ctrl_num
	AND	trx.trx_type = cdt.trx_type
	AND	ret.item_code = cdt.item_code
	GROUP BY trx.doc_ctrl_num, trx.trx_type, cdt.item_code

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmuiq.cpp" + ", line " + STR( 116, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	


	UPDATE	#artrxcdt_work
	SET	qty_returned = cdt.qty_returned + ret.qty_returned,
		db_action = cdt.db_action | 1
	FROM	#min_seq_id seq, #arqty_returned ret, #artrxcdt_work cdt
	WHERE	ret.apply_to_num = seq.doc_ctrl_num
	AND	ret.apply_trx_type = seq.trx_type
	AND	ret.item_code = seq.item_code
	AND	seq.doc_ctrl_num = cdt.doc_ctrl_num
	AND	seq.trx_type = cdt.trx_type
	AND	seq.sequence_id = cdt.sequence_id
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmuiq.cpp" + ", line " + STR( 136, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"qty_returned from #artrxcdt_work before update"
		SELECT	trx_ctrl_num + ":" +
				STR(qty_returned, 10, 4)
		FROM	#artrxcdt_work
	END

	DROP TABLE	#min_seq_id
	DROP TABLE	#arqty_returned

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "arcmuiq.cpp", 151, "Leaving ARCMUpdateInvoiceQuantity_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arcmuiq.cpp" + ", line " + STR( 152, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMUpdateInvoiceQuantities_SP] TO [public]
GO
