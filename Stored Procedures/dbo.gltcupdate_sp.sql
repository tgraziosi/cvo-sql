SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[gltcupdate_sp]	@batch_ctrl_num	varchar(16),
 				@debug_level 	smallint = 0

AS

DECLARE
 	@result 		int

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcupdate.sp" + ", line " + STR( 54, 5 ) + " -- ENTRY: "

	UPDATE	gltcrecon 
	SET	posted_flag = 1,
		remote_state = gltc.remote_state
	FROM	gltcrecon a, #gltcpost_work gltc
	WHERE	a.trx_ctrl_num = gltc.trx_ctrl_num 
	AND     a.trx_type =  gltc.trx_type
	AND     gltc.posted_flag = 1
	AND	gltc.batch_code = @batch_ctrl_num
	
	IF( @@error != 0 )
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/gltcupdate.sp" + ", line " + STR( 100, 5 ) + " -- EXIT: "
			RETURN 34563
		END
END
GO
GRANT EXECUTE ON  [dbo].[gltcupdate_sp] TO [public]
GO
