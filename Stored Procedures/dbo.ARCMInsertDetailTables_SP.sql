SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMInsertDetailTables_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
						@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmidt.sp", 95, "Entering ARCMInsertDetailsTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmidt.sp" + ", line " + STR( 98, 5 ) + " -- ENTRY: "

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmidt.sp", 103, "Start inserting unposted invoice commision details into #arinpcom_work", @PERF_time_last OUTPUT

	INSERT #arinpcom_work
	(	
		trx_ctrl_num,		trx_type,		sequence_id,
		salesperson_code,	amt_commission,	percent_flag,
		exclusive_flag,	split_flag,		db_action
	)		
	SELECT	d.trx_ctrl_num,	d.trx_type,		d.sequence_id,
		d.salesperson_code,	d.amt_commission,	d.percent_flag,
		d.exclusive_flag,	d.split_flag,		0
	FROM	arinpcom d, #arinpchg_work h
	WHERE	d.trx_ctrl_num = h.trx_ctrl_num
	AND	d.trx_type = h.trx_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmidt.sp" + ", line " + STR( 119, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmidt.sp", 123, "Leaving ARINInsertDetailTables_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmidt.sp" + ", line " + STR( 124, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMInsertDetailTables_SP] TO [public]
GO
