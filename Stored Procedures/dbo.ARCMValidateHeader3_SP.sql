SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[ARCMValidateHeader3_SP]	@error_level	smallint,
					@debug_level	smallint = 0
AS

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvh3.sp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "

	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20229 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20229,
			"",			"",			0,
			amt_net,		4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	((amt_net) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20235 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20235,
			"",			"",			0,
			amt_gross+amt_tax+amt_freight-amt_discount-amt_discount_taken-amt_write_off_given,		
						4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	
(ABS((amt_gross+amt_tax+amt_freight-amt_discount-amt_discount_taken-amt_write_off_given)-(amt_net)) > 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20230 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20230,
			"",			"",			0,
			amt_discount,		4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	((amt_discount) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20232 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20232,
			"",			"",			0,
			amt_discount_taken,	4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	((amt_discount_taken) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20233 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20233,
			"",			"",			0,
			amt_write_off_given,	4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	((amt_write_off_given) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20244 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20244,
			"",			"",			0,
			rate_home,		4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	(ABS((rate_home)-(0.0)) < 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20243 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20243,
			"",			"",			0,
			rate_oper,		4,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	(ABS((rate_oper)-(0.0)) < 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20266 ) >= @error_level
	BEGIN
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
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20266,
			"",			"",			0,
			chg.amt_gross,	4,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM 	#arvalchg chg, #amt_gross cdt
		WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num
		AND	(ABS((chg.amt_gross + chg.amt_tax_included - chg.amt_discount)-(cdt.sum_amt_gross)) > 0.0000001)
		
		DROP TABLE #amt_gross
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20234 ) >= @error_level
	BEGIN
		SELECT trx_ctrl_num, SUM(amt_final_tax) amt_tax		-- mls 2/21/03 SCR 29216
		INTO	#tax_sum
		FROM	#arvaltax
		GROUP BY trx_ctrl_num
	
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20234,
			"",			"",			0,
			tax.amt_tax,		4,		tax.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, #tax_sum tax
		WHERE	chg.trx_ctrl_num = tax.trx_ctrl_num
		AND	(ABS((chg.amt_tax)-(tax.amt_tax)) > 0.0000001)
		
		DROP TABLE #tax_sum
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20231 ) >= @error_level
	BEGIN
		SELECT trx_ctrl_num, SUM(discount_amt) discount_amt
		INTO	#disc_sum
		FROM	#arvalcdt
		GROUP BY trx_ctrl_num
	
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20231,
			"",			"",			0,
			chg.amt_discount,	4,		chg.trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg chg, #disc_sum disc
		WHERE	chg.trx_ctrl_num = disc.trx_ctrl_num
		AND	(ABS((chg.amt_discount)-(disc.discount_amt)) > 0.0000001)
		
		DROP TABLE #disc_sum
	END

	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvh3.sp" + ", line " + STR( 294, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateHeader3_SP] TO [public]
GO
