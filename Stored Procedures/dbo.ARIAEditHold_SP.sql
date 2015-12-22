SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARIAEditHold_SP]	@put_on_hold smallint,
						@debug_level smallint
AS

DECLARE	@batch_mode	smallint

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaeh.sp" + ", line " + STR( 26, 5 ) + " -- ENTRY: "
	
	CREATE TABLE #batchcodes
	(
		batch_code	varchar(8)
	)

	IF (@put_on_hold = 1)
	BEGIN

		SELECT	@batch_mode = batch_proc_flag FROM arco
		
		IF @batch_mode = 1
		BEGIN
			INSERT #batchcodes(batch_code)
			SELECT DISTINCT a.batch_code
			FROM arinpchg a, #ewerror b, aredterr c
			WHERE a.trx_ctrl_num = b.trx_ctrl_num
	 		AND a.trx_type = 2051
			AND b.err_code = c.e_code
			AND c.e_level > 2
		END

		BEGIN TRANSACTION
		
		UPDATE	arinpchg
 		SET	hold_flag = 1
		FROM	arinpchg a, #ewerror b, aredterr c
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2051
		AND	b.err_code = c.e_code
		AND	c.e_level > 2

		
	 	IF @batch_mode = 1
		BEGIN
		 	UPDATE batchctl
			SET hold_flag = 1,
			 number_held =(SELECT SUM(hold_flag) 
			 FROM	arinpchg
						WHERE arinpchg.batch_code = batchctl.batch_ctrl_num)
			FROM batchctl, #batchcodes b
			WHERE batchctl.batch_ctrl_num = b.batch_code
		END

		COMMIT TRANSACTION
	END

	DROP TABLE #batchcodes

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/ariaeh.sp" + ", line " + STR( 106, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARIAEditHold_SP] TO [public]
GO
