SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[arinvedt_sp] @only_error smallint,
 @debug_level smallint = 0
AS

DECLARE 
 @result smallint,
 @error_level smallint,
 @trx_type smallint, 
 @rec_inv smallint
 
BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "

 SELECT @trx_type = 0
 
 SET ROWCOUNT 1
 SELECT @trx_type = trx_type 
 FROM #arvalchg
 SET ROWCOUNT 0

 
 IF @trx_type = 0
 RETURN 0

 
CREATE TABLE #account (
				trx_ctrl_num	varchar(16),
				account_code	varchar(32),
				date_applied	int,
				currency_code	varchar(8),
				err_code_act	int,
				active_check	smallint,
				err_code_cur	int,
				cur_check	smallint
					)

 
 SELECT @rec_inv = 0
 IF @only_error = 5
 BEGIN
 SELECT @only_error = 1,
 @rec_inv = 1
 END
 
 IF @only_error = 1
 SELECT @error_level = 3
 ELSE
 SELECT @error_level = 2


 
 EXEC @result = ARINValidateHeader1_SP @error_level,
 @trx_type,
 @debug_level,
 @rec_inv
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 94, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = ARINValidateHeader2_SP @error_level,
 @trx_type,
 @debug_level,
 @rec_inv
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 107, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 EXEC @result = ARINValidateHeader3_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 120, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidateHeader4_SP @error_level,
 @trx_type,
 @debug_level,
 
 @rec_inv
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 134, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidateHeader5_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 146, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidateHeader6_SP @error_level,
 @trx_type,
 @debug_level,
 @rec_inv
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 159, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = ARINValidateTax_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 171, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidateAge_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 183, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidatePMT_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 195, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = ARINValidateDetail1_SP @error_level,
 @trx_type,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 207, 5 ) + " -- EXIT: "
 RETURN @result
 END
 
 
 EXEC @result = ARINValidateDetail2_SP @trx_type,
 @error_level,
 @debug_level
 IF( @result != 0 )
 BEGIN
 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvedt.sp" + ", line " + STR( 219, 5 ) + " -- EXIT: "
 RETURN @result
 END

 
 EXEC @result = ARValidateACCounT_SP @debug_level
 IF( @result != 0 )
 BEGIN
 RETURN @result
 END 


 DROP TABLE #account
 
 RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[arinvedt_sp] TO [public]
GO
