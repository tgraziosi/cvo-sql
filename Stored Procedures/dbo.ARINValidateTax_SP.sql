SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARINValidateTax_SP]	@error_level	smallint,
					@trx_type	smallint,
					@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 53, 5 ) + " -- ENTRY: "

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20063 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 60, 5 ) + " -- MSG: " + "Validate that the transaction has been printed"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20063,
			"",
			"",
			sequence_id,
			0.0,
			2,
			trx_ctrl_num,
			0,
			"",
			0
		FROM 	#arvaltax
	 	WHERE 	sequence_id < 0 
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20064 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 87, 5 ) + " -- MSG: " + "Validate that the tax type code exists in the tax type table"
		
		UPDATE	#arvaltax
		SET	temp_flag = 0
		
		UPDATE	#arvaltax
		SET	temp_flag = 1
		FROM	artxtype a
		WHERE	#arvaltax.tax_type_code = a.tax_type_code
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20064,
			tax_type_code,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvaltax
	 	WHERE	temp_flag = 0 
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20065 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 122, 5 ) + " -- MSG: " + "Validate that the amt taxable is positive"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20065,
			"",
			"",
			0,
			amt_taxable,
			4,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvaltax
	 	WHERE	((amt_taxable) < (0.0) - 0.0000001) 
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20066 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 149, 5 ) + " -- MSG: " + "Validate that the amt gross is positive"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20066,
			"",
			"",
			0,
			amt_gross,
			4,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvaltax
	 	WHERE	((amt_gross) < (0.0) - 0.0000001) 
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20067 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 176, 5 ) + " -- MSG: " + "Validate that the amt tax is positive"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20067,
			"",
			"",
			0,
			amt_tax,
			4,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvaltax
	 	WHERE	((amt_tax) < (0.0) - 0.0000001) 
	END


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvt.sp" + ", line " + STR( 199, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateTax_SP] TO [public]
GO
