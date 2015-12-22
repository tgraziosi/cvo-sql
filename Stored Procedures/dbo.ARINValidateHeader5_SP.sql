SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ARINValidateHeader5_SP]	@error_level	smallint,
						@trx_type	smallint,
						@debug_level	smallint = 0
AS

DECLARE	
	@result	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 49, 5 ) + " -- ENTRY: "

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20047 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 56, 5 ) + " -- MSG: " + "Validate that the net amount of invoice is valid"
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	20047,
			"",				"",
			0,				amt_net,
			4,			trx_ctrl_num,
			0,				ISNULL(source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg
	 	WHERE 	((amt_net) < (0.0) - 0.0000001) 
		AND	#arvalchg.trx_type != 2021 
	END


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20048 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 87, 5 ) + " -- MSG: " + "Validate that the discount amount is valid"
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	20048,
			"",				"",
			0,				amt_discount,
			4,			trx_ctrl_num,
			0,				ISNULL(source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg
	 	WHERE 	((amt_discount) < (0.0) - 0.0000001)
	END


	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20049 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 118, 5 ) + " -- MSG: " + "Validate that the header discount total matches SUM(line item discount) "
		
		CREATE TABLE #discount
		(	
			trx_ctrl_num		varchar( 16 ),
			sum_discount_amt	float
		)
		
		INSERT #discount
		SELECT trx_ctrl_num, sum(discount_amt) 
		FROM	#arvalcdt 
		GROUP BY trx_ctrl_num

		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	20049,
			"",				"",
			0,				a.amt_discount,
			4,			a.trx_ctrl_num,
			0,				ISNULL(a.source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg a, #discount b
	 	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	(ABS((a.amt_discount)-(sum_discount_amt)) > 0.0000001)
		
		DROP TABLE #discount
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20050 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 163, 5 ) + " -- MSG: " + "Validate that the total tax matches the sum of taxes in the tax distribution table) "
		
		CREATE TABLE #tax
		(	
			trx_ctrl_num	varchar( 16 ),
			sum_amt_tax	float
		)
		
		INSERT #tax
		SELECT trx_ctrl_num, sum(amt_final_tax) 
		FROM	#arvaltax 
		GROUP BY trx_ctrl_num

		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	20050,
			"",				"",
			0,				amt_tax,
			4,			a.trx_ctrl_num,
			0,				ISNULL(a.source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg a, #tax b
	 	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	(ABS((a.amt_tax)-(sum_amt_tax)) > 0.0000001)
		
		DROP TABLE #tax
	END
	
	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20089 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 207, 5 ) + " -- MSG: " + "Validate that the sum of the payment matches the header "
		
		CREATE TABLE #amt_paid
		(	
			trx_ctrl_num	varchar( 16 ),
			sum_pmt	float
		)
		
		INSERT #amt_paid
		SELECT trx_ctrl_num, sum(amt_payment + amt_disc_taken) 
		FROM	#arvaltmp 
		GROUP BY trx_ctrl_num

		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	20089,
			"",				"",
			0,				amt_paid,
			4,			a.trx_ctrl_num,
			0,				ISNULL(a.source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg a, #amt_paid b
	 	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	(ABS((a.amt_paid)-(sum_pmt)) > 0.0000001)
		
		DROP TABLE #amt_paid
	END
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20090 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 251, 5 ) + " -- MSG: " + "Validate that the total tax matches the sum of taxes in the tax distribution table) "
		
		CREATE TABLE #amt_gross
		(	
			trx_ctrl_num	varchar( 16 ),
			sum_amt_gross	float
		)
		
		INSERT #amt_gross
		SELECT trx_ctrl_num, sum(extended_price) 
		FROM	#arvalcdt 
		GROUP BY trx_ctrl_num

		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,	20090,
			"",			 	"",
			0,				amt_gross,
			4,			a.trx_ctrl_num,
			0,				ISNULL(source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg a, #amt_gross b
	 	WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	(ABS((a.amt_gross + a.amt_tax_included - a.amt_discount)-(b.sum_amt_gross)) > 0.0000001)
		
		DROP TABLE #amt_gross
	END
	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh5.sp" + ", line " + STR( 289, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader5_SP] TO [public]
GO
