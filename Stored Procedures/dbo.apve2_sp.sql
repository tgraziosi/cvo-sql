SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[apve2_sp] @only_errors smallint,
						 @put_on_hold smallint,
						 @debug_level smallint = 0
AS

DECLARE
 @batch_mode smallint


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apve2.sp" + ", line " + STR( 43, 5 ) + " -- ENTRY: "



CREATE TABLE #temp_batchcodes ( batch_code varchar(16) )


IF (@put_on_hold = 1)
BEGIN
	SELECT @batch_mode = batch_proc_flag FROM apco
	IF @batch_mode = 1 
	BEGIN
		
		INSERT #temp_batchcodes ( batch_code )
		SELECT DISTINCT a.batch_code
		FROM apinpchg a, #ewerror b, apedterr c
		WHERE a.trx_ctrl_num = b.trx_ctrl_num
 AND a.trx_type = 4091
		AND b.err_code = c.err_code
		AND c.err_type = 0
	END

 BEGIN TRANSACTION 

 UPDATE apinpchg
 SET hold_flag = 1
 FROM apinpchg a, #ewerror b, apedterr c
 WHERE a.trx_ctrl_num = b.trx_ctrl_num
 AND a.trx_type = 4091
 AND b.err_code = c.err_code
 AND c.err_type = 0

	
	IF @batch_mode = 1
	BEGIN
		
	 	UPDATE batchctl
		SET hold_flag = 1,
		 number_held = (SELECT SUM(hold_flag) 
		 FROM apinpchg
							 WHERE apinpchg.batch_code = batchctl.batch_ctrl_num)
		FROM batchctl, #temp_batchcodes b
		WHERE batchctl.batch_ctrl_num = b.batch_code
	 
	END

	COMMIT TRANSACTION

	IF @batch_mode = 1
		DROP TABLE #temp_batchcodes

END



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apve2.sp" + ", line " + STR( 123, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[apve2_sp] TO [public]
GO
