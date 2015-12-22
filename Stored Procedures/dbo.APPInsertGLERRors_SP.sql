SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[APPInsertGLERRors_SP]
(
	@process_ctrl_num 	varchar(16), 
	@batch_code 		varchar(16),
	@debug_level		smallint = 0,
	@perf_level			smallint = 0
)
AS
	
BEGIN

	IF ( @debug_level > 0 )
	BEGIN
		SELECT 	"@process_ctrl_num=" + @process_ctrl_num +
				"@batch_code="+ @batch_code	

		SELECT "Dumping from #trxerror..."
		SELECT "journal_ctrl_num = " + journal_ctrl_num +
				"sequence_id = " + STR(sequence_id, 8) +
				"error_code = " + STR(error_code, 8)
		FROM	#trxerror
	END
	
	INSERT perror
	(	process_ctrl_num,	batch_code,		module_id,
		err_code,			info1,			info2,
		infoint,			infofloat,		flag1,
		trx_ctrl_num,		sequence_id,	source_ctrl_num,
		extra
	)
	SELECT @process_ctrl_num,	@batch_code,	6000,	
			error_code,			"",				"",
			0,					0.0,			5,
			journal_ctrl_num,	sequence_id,	"",			
			0
	FROM	#trxerror	
	
	TRUNCATE TABLE #trxerror
	TRUNCATE TABLE #gltrx
	TRUNCATE TABLE #gltrxdet

END
GO
GRANT EXECUTE ON  [dbo].[APPInsertGLERRors_SP] TO [public]
GO
