SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARINInsertDetailTables_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint = 0,
 		@perf_level		smallint = 0	
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE
 @result 	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 101, "Entering ARINInsertDetailsTables_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinidt.sp" + ", line " + STR( 104, 5 ) + " -- ENTRY: "

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 109, "Start inserting unposted invoice commision details into #arinpcom_work", @PERF_time_last OUTPUT
 INSERT #arinpcom_work
 (	
		trx_ctrl_num,		trx_type,
		sequence_id,		salesperson_code,	amt_commission,
		percent_flag,		exclusive_flag,	split_flag,
		db_action
	)		
 SELECT 	
 	d.trx_ctrl_num,		d.trx_type,			
 	d.sequence_id,		d.salesperson_code,	d.amt_commission,		
 	d.percent_flag,		d.exclusive_flag,	d.split_flag,
		0
 FROM arinpcom d, #arinpchg_work h
 WHERE d.trx_ctrl_num = h.trx_ctrl_num
 AND d.trx_type = h.trx_type
 IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinidt.sp" + ", line " + STR( 127, 5 ) + " -- EXIT: "
 RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 130, "Done inserting unposted invoice commision details into #arinpcom_work", @PERF_time_last OUTPUT

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 135, "Start inserting unposted invoice payment details into #arinptmp_work", @PERF_time_last OUTPUT
 INSERT #arinptmp_work
 (	
		trx_ctrl_num,		doc_ctrl_num,
		trx_desc,		date_doc,		customer_code,
		payment_code,		amt_payment,		
		prompt1_inp,		prompt2_inp,		prompt3_inp,		
		prompt4_inp,		amt_disc_taken,	cash_acct_code,		
		db_action
	)		
 SELECT 	
		d.trx_ctrl_num,	d.doc_ctrl_num,
		d.trx_desc,		d.date_doc,		d.customer_code,
		d.payment_code,	d.amt_payment,	
		d.prompt1_inp,	d.prompt2_inp,	d.prompt3_inp,		
		d.prompt4_inp,	d.amt_disc_taken,	d.cash_acct_code,	
		0
 FROM arinptmp d, #arinpchg_work h
 WHERE	d.trx_ctrl_num = h.trx_ctrl_num
 IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinidt.sp" + ", line " + STR( 156, 5 ) + " -- EXIT: "
 RETURN 34563
	END
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 159, "Done inserting unposted invoice payment details into #arinptmp_work", @PERF_time_last OUTPUT

	
	IF ( @perf_level >= 2 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 164, "Start inserting recurrung cycle details into #arcycle_work", @PERF_time_last OUTPUT

 INSERT #arcycle_work
 (	
		cycle_code,		cycle_desc,
		date_last_used,	date_from,	cycle_type,
		number,		use_type,	cancel_flag,
		date_cancel,		amt_base,	tracked_flag,
		amt_tracked_balance,	nat_cur_code
	)		
 SELECT 	
		cycle_code,		cycle_desc,
		date_last_used,	date_from,	cycle_type,
		number,		use_type,	cancel_flag,
		date_cancel,		amt_base,	tracked_flag,
		amt_tracked_balance,	d.nat_cur_code
	FROM arcycle d
	WHERE d.cycle_code in 
		(SELECT recurring_code 
		FROM arcycle d, arinpchg h
		WHERE h.recurring_code = d.cycle_code
		AND h.recurring_flag = 1)
 IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinidt.sp" + ", line " + STR( 188, 5 ) + " -- EXIT: "
 RETURN 34563
	END

	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arinidt.sp", 192, "Leaving ARINInsertDetailTables_SP", @PERF_time_last OUTPUT
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinidt.sp" + ", line " + STR( 193, 5 ) + " -- EXIT: "
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINInsertDetailTables_SP] TO [public]
GO
