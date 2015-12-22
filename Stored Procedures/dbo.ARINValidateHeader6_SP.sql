SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ARINValidateHeader6_SP]	@error_level	smallint,
						@trx_type	smallint,
						@debug_level	smallint = 0,
						@rec_inv	smallint
AS

DECLARE	
	@result	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20051 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 55, 5 ) + " -- MSG: " + "Validate that the amount paid is positive"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20051,
			"",
			"",
			0,
			amt_paid,
			4,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg
	 	WHERE	((amt_paid) < (0.0) - 0.0000001)
		
	END

	
	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20052 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 83, 5 ) + " -- MSG: " + "Validate that the net amt = gross + tax + freight - disc"

		
		INSERT	#ewerror
		SELECT 2000,
		 	20052,
			"",
			"",
			0,
			amt_net,
			4,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg a, glcurr_vw b
	 	WHERE	a.nat_cur_code = b.currency_code
		AND	ABS(a.amt_gross + a.amt_tax + a.amt_freight - a.amt_discount - a.amt_net) > b.rounding_factor
	END

	
	IF (( SELECT e_level FROM aredterr WHERE e_code = 20053 ) >= @error_level )
 AND @rec_inv = 0
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 112, 5 ) + " -- MSG: " + "Check if an unposted invoice for the same customer and amt exists"

		
		INSERT	#ewerror
		SELECT DISTINCT 2000,
		 	20053,
			a.customer_code,
			"",
			0,
			0.0,
			1,
			a.trx_ctrl_num,
			0,
			ISNULL(a.source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg a, arinpchg b
		WHERE	a.customer_code = b.customer_code
		AND	b.trx_type <= 2031
		AND	(ABS((a.amt_net)-(b.amt_net)) < 0.0000001)
		AND	a.trx_ctrl_num != b.trx_ctrl_num
	END	


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20058 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 142, 5 ) + " -- MSG: " + "Validating that the currency code exists in the currency code table"

		UPDATE	#arvalchg
		SET	temp_flag = 0

		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glcurr_vw b
		WHERE	#arvalchg.nat_cur_code = b.currency_code
						
		
		INSERT	#ewerror
		SELECT 2000,
		 	20058,
			nat_cur_code,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	 	WHERE	temp_flag = 0
	END


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20059 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 180, 5 ) + " -- MSG: " + "Validating that the home rate type exists in the rate type table"

		UPDATE	#arvalchg
		SET	temp_flag = 0

		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glrtype_vw b
		WHERE	b.rate_type = #arvalchg.rate_type_home
						
		
		INSERT	#ewerror
		SELECT 2000,
		 	20059,
			rate_type_home,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	 	WHERE	temp_flag = 0
	END

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20060 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 217, 5 ) + " -- MSG: " + "Validating that the oper rate type exists in the rate type table"

		UPDATE	#arvalchg
		SET	temp_flag = 0

		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	glrtype_vw b
		WHERE	b.rate_type = #arvalchg.rate_type_oper
						
		
		INSERT	#ewerror
		SELECT 2000,
		 	20060,
			rate_type_oper,
			"",
			0,
			0.0,
			1,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	 	WHERE	temp_flag = 0
	END


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20061 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "Validate that the operational rate is not 0.0"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20061,
			"",
			"",
			0,
			rate_oper,
			4,
			trx_ctrl_num,
			0,
		 ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	 	WHERE	(ABS((rate_oper)-(0.0)) < 0.0000001)
	END

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20062 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 281, 5 ) + " -- MSG: " + "Validate that the home rate is not 0.0"
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20062,
			"",
			"",
			0,
			rate_home,
			4,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg 
	 	WHERE	(ABS((rate_home)-(0.0)) < 0.0000001)
	END

	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh6.sp" + ", line " + STR( 302, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader6_SP] TO [public]
GO
