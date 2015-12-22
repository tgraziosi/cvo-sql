SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARInsertPERRors_SP] 	@process_ctrl_num 	varchar(16),
						@batch_ctrl_num	varchar(16), 
				 		@debug_level 		smallint = 0
			
AS

DECLARE @result int 

BEGIN 

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariperr.sp" + ", line " + STR( 32, 5 ) + " -- ENTRY: "

	IF (SELECT COUNT(*) FROM #ewerror) = 0
 		RETURN 0

	INSERT perror
	(	process_ctrl_num,	batch_code,		module_id,
		err_code,		info1,			info2,
		infoint,		infofloat,		flag1,
		trx_ctrl_num,		sequence_id,		source_ctrl_num,
		extra
	)
	SELECT @process_ctrl_num,	@batch_ctrl_num,	module_id,
		err_code,		info1,	 		info2,
	 	infoint,	 	infofloat,		flag1,
		trx_ctrl_num,		sequence_id,		source_ctrl_num,
		extra 
	FROM #ewerror

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariperr.sp" + ", line " + STR( 51, 5 ) + " -- EXIT: "
	
			
	RETURN 34562
END
GO
GRANT EXECUTE ON  [dbo].[ARInsertPERRors_SP] TO [public]
GO
