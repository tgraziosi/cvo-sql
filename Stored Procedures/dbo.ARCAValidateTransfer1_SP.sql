SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARCAValidateTransfer1_SP]	@error_level smallint, 
						@debug_level smallint = 0
AS

DECLARE	
	@result		smallint,
	@transfer_exists	smallint


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 35, 5 ) + " -- ENTRY: "

	
	
	SELECT @transfer_exists = SIGN(COUNT(void_type))
	FROM	#arvalpyt
	WHERE	void_type = 4	

	SELECT "@error_level = " + STR(@error_level,4)
	SELECT "@transfer_exists = " + STR(@transfer_exists,4)
	
	
	IF (SELECT e_level * @transfer_exists FROM aredterr WHERE e_code = 20615) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 77, 5 ) + " -- MSG: " + "Validate the CR Adj Transfer recipient customer exists"

		UPDATE	#arvalpyt
		SET	temp_flag = 0
		
		UPDATE	#arvalpyt
		SET	temp_flag = 1
		FROM	arcrtran crt, arcust arcust
		WHERE	#arvalpyt.trx_ctrl_num = crt.trx_ctrl_num
		AND	crt.customer_code = arcust.customer_code
		AND	#arvalpyt.void_type = 4


		INSERT #ewerror
		SELECT	2000,
			20615,
			crt.customer_code,
			"",
			0,
			0.0,
			1,
			pyt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpyt pyt, arcrtran crt 
		WHERE	pyt.trx_ctrl_num = crt.trx_ctrl_num
		AND	pyt.temp_flag = 0
	END

	
	IF (SELECT e_level * @transfer_exists FROM aredterr WHERE e_code = 20616) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 114, 5 ) + " -- MSG: " + "Validate that the transfer has not previously been adjusted"

		UPDATE	#arvalpyt
		SET	temp_flag = 0
		
		UPDATE	#arvalpyt
		SET	temp_flag = 1
		FROM	artrxpdt trx
		WHERE	#arvalpyt.doc_ctrl_num = trx.doc_ctrl_num
		AND	#arvalpyt.customer_code = trx.customer_code
		AND	trx.trx_type = 2111
		AND	trx.void_flag = 1
		AND	#arvalpyt.void_type = 4
		

		INSERT #ewerror
		SELECT	2000,
			20616,
			doc_ctrl_num + " -- " + customer_code,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpyt 
		WHERE	temp_flag = 1
	END

	
	IF (SELECT e_level * @transfer_exists FROM aredterr WHERE e_code = 20617) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 150, 5 ) + " -- MSG: " + "Validate that the document number for the transfer receipient does not exist"

		UPDATE	#arvalpyt
		SET	temp_flag = 0
		
		UPDATE	#arvalpyt
		SET	temp_flag = 1
		FROM	arcrtran crt, artrx trx
		WHERE	#arvalpyt.trx_ctrl_num = crt.trx_ctrl_num
		AND	#arvalpyt.doc_ctrl_num = trx.doc_ctrl_num
		AND	crt.customer_code = trx.customer_code
		AND	trx.trx_type = 2111
		AND	trx.payment_type = 1
		AND	#arvalpyt.void_type = 4
		

		INSERT #ewerror
		SELECT	2000,
			20617,
			pyt.doc_ctrl_num + " -- " + crt.customer_code,
			"",
			0,
			0.0,
			1,
			pyt.trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpyt pyt, arcrtran crt
		WHERE	pyt.trx_ctrl_num = crt.trx_ctrl_num
		AND	pyt.temp_flag = 1
	END

	
	IF (SELECT e_level * @transfer_exists FROM aredterr WHERE e_code = 20618) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 190, 5 ) + " -- MSG: " + "Validate the cash receipt is not being transferred to the same customer"

		UPDATE	#arvalpyt
		SET	temp_flag = 0
		
		UPDATE	#arvalpyt
		SET	temp_flag = 1
		FROM	arcrtran crt
		WHERE	#arvalpyt.trx_ctrl_num = crt.trx_ctrl_num
		AND	#arvalpyt.customer_code = crt.customer_code
		AND	#arvalpyt.void_type = 4


		INSERT #ewerror
		SELECT	2000,
			20618,
			doc_ctrl_num + " -- " + customer_code,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalpyt 
		WHERE	temp_flag = 1
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcavt1.sp" + ", line " + STR( 221, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCAValidateTransfer1_SP] TO [public]
GO
