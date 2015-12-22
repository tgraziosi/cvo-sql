SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



















 






















































































 



					 










































 































































































































































































































































































































































































































































































































































































 







































































































































































































































































 

CREATE PROC [dbo].[ARCAAdjustDiscWOffs_SP]		@batch_ctrl_num	varchar(16),
						@debug_level		smallint = 0,
						@perf_level		smallint = 0
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	
	@result		int,
	@max_sequence_id	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaadwo.sp", 67, "Entering ARCAAdjustDiscWOffs_SP", @PERF_time_last OUTPUT

BEGIN 
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 70, 5 ) + " -- ENTRY: "

	
	CREATE TABLE	#min_records
		(
			sub_apply_num		varchar(16),
			sub_apply_type	smallint,
			trx_ctrl_num		varchar(16),
			sequence_id		int
		)
		IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 93, 5 ) + " -- EXIT: "
			RETURN 34563
		END
	
	SELECT	sub_apply_num, sub_apply_type, MIN(trx_ctrl_num) trx_ctrl_num
	INTO	#t
	FROM	#arinppdt_work
	GROUP BY sub_apply_num, sub_apply_type
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 103, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	CREATE INDEX #t_ind ON #t(sub_apply_num, sub_apply_type)
	 
	INSERT	#min_records (sub_apply_num, sub_apply_type, trx_ctrl_num, sequence_id) 
	SELECT	#arinppdt_work.sub_apply_num, #arinppdt_work.sub_apply_type, 
		#arinppdt_work.trx_ctrl_num, MIN(#arinppdt_work.sequence_id) 
	FROM	#t, #arinppdt_work 
	WHERE #t.sub_apply_num = #arinppdt_work.sub_apply_num 
	AND	#t.sub_apply_type = #arinppdt_work.sub_apply_type
	AND	#t.trx_ctrl_num = #arinppdt_work.trx_ctrl_num 
	GROUP BY #arinppdt_work.sub_apply_num, #arinppdt_work.sub_apply_type, #arinppdt_work.trx_ctrl_num
	
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF (@debug_level > 0)
	BEGIN
		SELECT " dumping #min_records"
		SELECT	" sub_apply_num = " + sub_apply_num +
			" sub_apply_type = " + STR(sub_apply_type,6) +
			" trx_ctrl_num = " + trx_ctrl_num +
			" sequence_id = " + STR(sequence_id, 6)
		FROM	#min_records
	END
	
	
	UPDATE #arinppdt_work
	SET	amt_disc_taken = 0.0,
		amt_max_wr_off = 0.0,
		inv_amt_disc_taken = 0.0,
		inv_amt_max_wr_off = 0.0
	FROM	#arinppyt_work pyt, #arinppdt_work pdt
	WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
	AND	pyt.trx_type = pdt.trx_type
	AND	pyt.batch_code = @batch_ctrl_num

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 150, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	
	CREATE TABLE	#disc_and_wroff
			(	sub_apply_num		varchar(16),
				sub_apply_type	smallint,
				inv_amt_discount	float,
				inv_amt_wr_off	float
			)
			IF( @@error != 0 )
			BEGIN
				IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 170, 5 ) + " -- EXIT: "
				RETURN 34563
			END

	
	INSERT	#disc_and_wroff
	SELECT	inp.sub_apply_num, 
		inp.sub_apply_type, 
		SUM(SIGN(2111.5 - trx.trx_type) * trx.inv_amt_disc_taken), 
		SUM(SIGN(2111.5 - trx.trx_type) * trx.inv_amt_wr_off)
	FROM	artrxpdt trx, #min_records inp
	WHERE	trx.sub_apply_num = inp.sub_apply_num
	AND	trx.sub_apply_type = inp.sub_apply_type
	AND	trx.trx_type >= 2111
	AND	trx.trx_type <= 2121
	GROUP BY inp.sub_apply_num, inp.sub_apply_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 194, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	IF (@debug_level > 0)
	BEGIN
		SELECT "dumping disc_and_wroff"
		SELECT	" sub_apply_num = " + sub_apply_num +
			" sub_apply_type = " + STR(sub_apply_type,8) +
			" inv_amt_discount = " + STR(inv_amt_discount,10,2) +
			" inv_amt_wr_off = " + STR(inv_amt_wr_off,10,2)
		FROM	#disc_and_wroff
	END
		

	UPDATE #arinppdt_work
	SET	inv_amt_disc_taken = post.inv_amt_discount,
		inv_amt_max_wr_off = post.inv_amt_wr_off, 
		wr_off_flag = 1
	FROM	#arinppdt_work pdt, #min_records minrec, #disc_and_wroff post
	WHERE	pdt.trx_ctrl_num = minrec.trx_ctrl_num
	AND	pdt.sequence_id = minrec.sequence_id
	AND	pdt.sub_apply_num = minrec.sub_apply_num
	AND	pdt.sub_apply_type = minrec.sub_apply_type
	AND	minrec.sub_apply_num = post.sub_apply_num
	AND	minrec.sub_apply_type = post.sub_apply_type

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcaadwo.sp" + ", line " + STR( 223, 5 ) + " -- EXIT: "
		RETURN 34563
	END
	
	
	UPDATE	#arinppdt_work
	SET	db_action = db_action | 4
	WHERE amt_applied + amt_disc_taken + amt_max_wr_off
	 +inv_amt_applied + inv_amt_disc_taken + inv_amt_max_wr_off = 0.0
	
	IF (@debug_level > 0)
	BEGIN
		SELECT	"dumping #arinppdt_work after discount and wr off adjustment"
		SELECT	"trx_ctrl_num = " + trx_ctrl_num +
			" doc_ctrl_num = " + doc_ctrl_num +
			" customer_code = " + customer_code +
			" trx_type = " + STR(trx_type,6) +
			" amt_applied = " + STR(amt_applied,10,2) +
			" inv_amt_applied = " + STR(inv_amt_applied,10,2) +
			" inv_amt_disc_taken = " + STR(inv_amt_disc_taken,8,2) +
			" inv_amt_max_wr_off = " + STR(inv_amt_max_wr_off,8,2)
		FROM	#arinppdt_work
	END
	
	DROP TABLE	#min_records
	DROP TABLE	#disc_and_wroff
	DROP TABLE	#t	
	
	
	IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcaadwo.sp", 256, "Returning from ARCAAdjustDiscWOffs_SP", @PERF_time_last OUTPUT
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[ARCAAdjustDiscWOffs_SP] TO [public]
GO
