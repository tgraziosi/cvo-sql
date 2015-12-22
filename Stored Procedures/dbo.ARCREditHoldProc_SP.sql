SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ARCREditHoldProc_SP]	@put_on_hold smallint,
					@debug_level smallint,
					@process_ctrl_num varchar(16)
AS					

DECLARE	@batch_mode	smallint
	

BEGIN

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "temp\\arcrehp.sp" + ", line " + STR( 30, 5 ) + " -- ENTRY: "

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
			FROM   arinppyt a, perror b, aredterr c
			WHERE  a.trx_ctrl_num = b.trx_ctrl_num
	      		AND    a.trx_type = 2111
			AND    b.err_code = c.e_code
			AND    c.e_level > 2
			AND    b.process_ctrl_num = @process_ctrl_num
		END

		BEGIN TRANSACTION
		





		UPDATE	arinppyt
    		SET	hold_flag = 1
		FROM	arinppyt a, perror b, aredterr c
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2111
		AND	b.err_code = c.e_code
		AND	c.e_level > 2
		AND     b.process_ctrl_num = @process_ctrl_num
		
		


		UPDATE	arinppyt
		SET     doc_amount = x.amt_on_acct
		FROM	arinppyt a, perror b, aredterr c, artrx x
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND     a.doc_ctrl_num = x.doc_ctrl_num
		AND	a.trx_type = 2111
		AND	b.err_code = c.e_code
		AND	c.e_level > 2
		AND     b.process_ctrl_num = @process_ctrl_num
		 
		
		UPDATE arinpstlhdr
		SET hold_flag = 1 
		FROM  arinpstlhdr e,arinppyt a, perror b, aredterr c
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.trx_type = 2111
		AND	b.err_code = c.e_code
		AND	c.e_level > 2
		AND     b.process_ctrl_num = @process_ctrl_num
		AND     e.settlement_ctrl_num = a.settlement_ctrl_num


	 	IF @batch_mode = 1
		BEGIN
		 	UPDATE batchctl
			SET    hold_flag = 1,
			       number_held =(SELECT SUM(hold_flag) 
			                     FROM	arinppyt
						WHERE  arinppyt.batch_code = batchctl.batch_ctrl_num)
			FROM   batchctl, #batchcodes b
			WHERE  batchctl.batch_ctrl_num = b.batch_code
		END

		COMMIT TRANSACTION
	END
	
	DROP TABLE #batchcodes

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "temp\\arcrehp.sp" + ", line " + STR( 136, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARCREditHoldProc_SP] TO [public]
GO
