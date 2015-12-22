SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[APPInsertIVErrors_SP]
						@process_ctrl_num 	varchar(16), 
						@batch_code 		varchar(16),
						@debug_level		smallint,
						@perf_level		smallint

AS
	
BEGIN
	IF ( @debug_level > 0 )
	BEGIN
		SELECT "Dumping from #ivtrxerr..."
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"sequence_id = " + STR(sequence_id, 8) +
			"error_code = " + STR(error_code, 8)
		FROM	#ivtrxerr
	END

	INSERT perror
	(	process_ctrl_num,	batch_code,	module_id,
		err_code,		info1,		info2,
		infoint,		infofloat,	flag1,
		trx_ctrl_num,		sequence_id,	source_ctrl_num,
		extra
	)
	SELECT @process_ctrl_num,	@batch_code,	5000,	
		error_code,		"",		"",
		0,			0.0,		5,
		trx_ctrl_num,		sequence_id,	"",
		0
	FROM	#ivtrxerr

	IF( @@error != 0 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/appiive.sp" + ", line " + STR( 64, 5 ) + " -- EXIT: "
		RETURN @@error
	END

	TRUNCATE TABLE #ivtrxerr
	TRUNCATE TABLE #ivtrx
	TRUNCATE TABLE #ivtrxdet

END
GO
GRANT EXECUTE ON  [dbo].[APPInsertIVErrors_SP] TO [public]
GO
