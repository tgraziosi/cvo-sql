SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE	[dbo].[cminval2_sp] 	@process_ctrl_num 	varchar(16), 
					@batch_code 		varchar(16),
					@debug_level 		smallint = 0
			
AS

DECLARE @result int 

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cminval2.sp" + ", line " + STR( 30, 5 ) + " -- ENTRY: "

IF (SELECT COUNT(*) FROM #ewerror) = 0
 RETURN 0


INSERT perror(
			 process_ctrl_num,
				batch_code,
			 module_id,
				err_code,
				info1,
				info2,
				infoint,
				infofloat,
				flag1,
				trx_ctrl_num,
				sequence_id,
				source_ctrl_num,
				extra
			 )
SELECT 		 @process_ctrl_num,
				ISNULL(@batch_code,""),
				module_id,
				err_code,
				info1,
				info2,
				infoint,
				infofloat,
				flag1,
				trx_ctrl_num,
				sequence_id,
				source_ctrl_num,
				extra 
FROM #ewerror





IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/cminval2.sp" + ", line " + STR( 70, 5 ) + " -- EXIT: "
			
RETURN -3

GO
GRANT EXECUTE ON  [dbo].[cminval2_sp] TO [public]
GO
