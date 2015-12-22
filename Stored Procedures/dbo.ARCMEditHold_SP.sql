SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARCMEditHold_SP]	@put_on_hold smallint,
					@debug_level smallint
AS

DECLARE	@trx_ctrl_num		varchar(16),
		@trx_type		smallint,
		@home_curr_precision	smallint,
		@oper_curr_precision	smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmeh.sp" + ", line " + STR( 50, 5 ) + " -- ENTRY: "
	
	CREATE TABLE #temp_batchcodes
	(
		batch_code	varchar(8)
	)
	
	
	UPDATE	#arvalchg
	SET	temp_flag = 0
	
	UPDATE	#arvalchg
	SET	temp_flag = 1
	FROM	#arvalchg chg, #ewerror werr, aredterr err
	WHERE	chg.trx_ctrl_num = werr.trx_ctrl_num
	AND	werr.err_code = err.e_code
	AND	err.e_level >= 3	

	IF (@put_on_hold = 1)
	BEGIN
		
		INSERT #temp_batchcodes(batch_code)
		SELECT DISTINCT chg.batch_code
		FROM #arvalchg chg, arco
		WHERE temp_flag = 1
		AND	arco.batch_proc_flag = 1

		
 		BEGIN TRANSACTION 

		UPDATE	arinpchg
 		SET	hold_flag = 1
		FROM	#arvalchg val, arinpchg inp
		WHERE	val.trx_ctrl_num = inp.trx_ctrl_num
		AND	val.trx_type = inp.trx_type
		AND	val.temp_flag = 1 

		
	 	UPDATE batchctl
		SET hold_flag = 1,
		 number_held =(SELECT SUM(hold_flag) 
		 FROM	#arvalchg
					WHERE #arvalchg.batch_code = batchctl.batch_ctrl_num)
		FROM batchctl, #temp_batchcodes b
		WHERE batchctl.batch_ctrl_num = b.batch_code

		COMMIT TRANSACTION
	END
	
	DROP TABLE #temp_batchcodes

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmeh.sp" + ", line " + STR( 133, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCMEditHold_SP] TO [public]
GO
