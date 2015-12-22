SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMCreateWorkTable_SP]	@batch_ctrl_num	varchar( 16 ),
						@debug_level		smallint,
						@perf_level		smallint
AS






DECLARE
 @PERF_time_last datetime

SELECT @PERF_time_last = GETDATE()















									







DECLARE	@result	int

IF ( @perf_level >= 1 ) EXEC perf_sp @batch_ctrl_num, "tmp/arcmcwt.sp", 61, "Entering ARCMCreateWorkTable_SP", @PERF_time_last OUTPUT

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmcwt.sp" + ", line " + STR( 64, 5 ) + " -- ENTRY: "

	INSERT	#arcmtemp
	(
		trx_ctrl_num,	trx_type,	journal_ctrl_num
	)
	SELECT	trx_ctrl_num,	trx_type,	' '
	FROM	#arinpchg_work
	WHERE	batch_code = @batch_ctrl_num
	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmcwt.sp" + ", line " + STR( 75, 5 ) + " -- EXIT: "
		RETURN 34563
	END

	IF( @debug_level >= 4 )
	BEGIN
		SELECT	"#arcmtemp- trx_ctrl_num:trx_type:journal_ctrl_num"
		SELECT	trx_ctrl_num + ":" +
			STR(trx_type, 6) + ":" +
			journal_ctrl_num
		FROM	#arcmtemp
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmcwt.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
	RETURN 0 
END
GO
GRANT EXECUTE ON  [dbo].[ARCMCreateWorkTable_SP] TO [public]
GO
