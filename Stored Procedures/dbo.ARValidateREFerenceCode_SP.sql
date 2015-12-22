SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


						

CREATE PROC [dbo].[ARValidateREFerenceCode_SP]	@rule_flag	smallint,
						@trx_type	smallint,
						@debug_level	smallint = 0
AS

DECLARE	
	@result		smallint,
	@e_code		int, 
	@e_code2		int	

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 59, 5 ) + " -- ENTRY: "
	
	IF ( @debug_level > 2 )
	BEGIN
		SELECT "@rule_flag = " + STR(@rule_flag, 3)
		SELECT "trx_ctrl_num = " + trx_ctrl_num +
			"sequence_id = " + STR(sequence_id, 4) +
			"account_code = " + account_code +
			"reference_code = " + reference_code
		FROM	#aractref
	END
	
	
	
	
	IF ( @rule_flag & 1 = 1 )
	BEGIN
	
		SELECT @e_code = 
			(1-ABS(SIGN(@trx_type-2031)))*20079 +
			(1-ABS(SIGN(@trx_type-2051)))*20806 +
			(1-ABS(SIGN(@trx_type-2032)))*20250 +
			(1-ABS(SIGN(@trx_type-2111)))*20422
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 94, 5 ) + " -- MSG: " + "Validate that the reference code either exists or is blank"
		
		UPDATE	#aractref
		SET	temp_flag = 0
		WHERE	temp_flag > 0
		
		UPDATE	#aractref
		SET	temp_flag = 1
		WHERE	( LTRIM(reference_code) IS NULL OR LTRIM(reference_code) = " " )
		
		UPDATE	#aractref
		SET	temp_flag = 1
		FROM	glref
		WHERE	#aractref.reference_code = glref.reference_code
		AND	temp_flag = 0
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	@e_code,
			reference_code,		"",
			0,				0.0,
			1,			trx_ctrl_num,
			sequence_id,			"",
			0		
		FROM 	#aractref
	 	WHERE 	temp_flag = 0
		
		IF ( @@rowcount > 0 )
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 132, 5 ) + " -- MSG: " + "Error:Reference Code not exist in GL!"
			
	END

	
	IF ( @rule_flag & 2 = 2 )
	BEGIN
		SELECT @e_code = 
			(1-ABS(SIGN(@trx_type-2031)))*20080 +
			(1-ABS(SIGN(@trx_type-2051)))*20807 +
			(1-ABS(SIGN(@trx_type-2032)))*20255 +
			(1-ABS(SIGN(@trx_type-2111)))*20423
		
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 147, 5 ) + " -- MSG: " + "Check is reference code is required"
		
		UPDATE	#aractref
		SET	temp_flag = 0
		WHERE	temp_flag > 0
		
		UPDATE	#aractref
		SET	temp_flag = 1
		FROM	glrefact
		WHERE	#aractref.account_code LIKE glrefact.account_mask
		AND	glrefact.reference_flag = 1	 
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	@e_code,
			#aractref.account_code,	"",
			0,				0.0,
			1,			trx_ctrl_num,
			sequence_id,			"",
			0
		FROM 	#aractref, glrefact
	 	WHERE 	#aractref.account_code LIKE glrefact.account_mask
		AND	glrefact.reference_flag = 3 
		AND	( LTRIM(#aractref.reference_code) IS NULL OR LTRIM(#aractref.reference_code) = " " )
		AND	#aractref.temp_flag = 0 
		
		IF ( @@rowcount > 0 )
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 184, 5 ) + " -- MSG: " + "Error:Reference Code is required!"
	END
	
	SELECT @e_code = 
			(1-ABS(SIGN(@trx_type-2031)))*20082 +
			(1-ABS(SIGN(@trx_type-2051)))*20809 +
			(1-ABS(SIGN(@trx_type-2032)))*20257 +
			(1-ABS(SIGN(@trx_type-2111)))*20425
			
	SELECT @e_code2 =
			(1-ABS(SIGN(@trx_type-2031)))*20081 +
			(1-ABS(SIGN(@trx_type-2051)))*20808 +
			(1-ABS(SIGN(@trx_type-2032)))*20256 +
			(1-ABS(SIGN(@trx_type-2111)))*20424
	
	
	IF ( @rule_flag & 4 = 4 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 204, 5 ) + " -- MSG: " + "Validate the detail line reference code is not excluded"
		
		UPDATE	#aractref
		SET	temp_flag = 0
		WHERE	temp_flag > 0
		
		
		UPDATE	#aractref
		SET	temp_flag = 1
		FROM	#aractref cdt, glref ref, glrefact act, glratyp typ
		WHERE	cdt.reference_code = ref.reference_code
		AND	ref.reference_type = typ.reference_type
		AND	typ.account_mask = act.account_mask
		AND	act.reference_flag = 1 
		AND	cdt.account_code LIKE act.account_mask
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000,	@e_code,
			reference_code,		"",
			0,				0.0,
			1,			trx_ctrl_num,
			sequence_id,			"",
			0
		FROM	#aractref cdt
		WHERE	temp_flag = 1
		
		IF ( @@rowcount > 0 )
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 245, 5 ) + " -- MSG: " + "Error:Invalid reference code!"
	END
	
	IF ( @rule_flag & 4 = 4 ) OR ( @rule_flag & 8 = 8 )
	BEGIN
		
		UPDATE	#aractref
		SET	temp_flag = 2
		FROM	glrefact act
		WHERE	#aractref.account_code LIKE act.account_mask
		AND	act.reference_flag > 1 
		AND	#aractref.temp_flag = 0
		AND	( LTRIM(#aractref.reference_code) IS NOT NULL AND LTRIM(#aractref.reference_code) != " " )
	END	
	
	
	IF ( @rule_flag & 8 = 8 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 267, 5 ) + " -- MSG: " + "Validate that a reference code is allowed for this account"
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	@e_code2,
			reference_code,		"",
			0,				0.0,
			1,			trx_ctrl_num,
			sequence_id,			"",
			0
		FROM 	#aractref 
	 	WHERE 	temp_flag = 0
		AND	( LTRIM(reference_code) IS NOT NULL AND LTRIM(reference_code) != " " )
		
		IF ( @@rowcount > 0 )
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 294, 5 ) + " -- MSG: " + "Error:No reference code allowed!"

	END

	
	IF ( @rule_flag & 4 = 4 )
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 303, 5 ) + " -- MSG: " + "Validate that the reference code is valid for the account code"
		
		UPDATE	#aractref
		SET	temp_flag = 3
		FROM	#aractref cdt, glref ref, glrefact act, glratyp typ
		WHERE	temp_flag = 2
		AND	cdt.reference_code = ref.reference_code
		AND	ref.reference_type = typ.reference_type
		AND	typ.account_mask = act.account_mask
		AND	cdt.account_code LIKE act.account_mask
		
		
		INSERT	#ewerror
		(
			module_id,			err_code,
			info1,				info2,
			infoint,			infofloat,
			flag1,				trx_ctrl_num,
			sequence_id,			source_ctrl_num,
			extra
		)
		SELECT 2000, 	@e_code,
			reference_code,		"",
			0,				0.0,
			1,			trx_ctrl_num,
			sequence_id,			"",
			0
		FROM 	#aractref 
	 	WHERE 	temp_flag = 2
		
		IF ( @@rowcount > 0 )
			IF ( @debug_level > 2 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 336, 5 ) + " -- MSG: " + "Error:Invalid reference code!"
	END

	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvrefc.sp" + ", line " + STR( 340, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARValidateREFerenceCode_SP] TO [public]
GO
