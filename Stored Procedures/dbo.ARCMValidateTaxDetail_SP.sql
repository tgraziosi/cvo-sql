SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMValidateTaxDetail_SP]	@error_level	smallint,
						@debug_level	smallint = 0
AS

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvtd.sp" + ", line " + STR( 44, 5 ) + " -- ENTRY: "

	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20245 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20245,
			"",			"",			sequence_id,
			0.0,			2,		trx_ctrl_num,
			sequence_id,		"",			0				
		FROM	#arvaltax
		WHERE	sequence_id <= 0
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20246 ) >= @error_level
	BEGIN
		UPDATE	#arvaltax
		SET	temp_flag = 0
		
		UPDATE	#arvaltax
		SET	temp_flag = 1
		FROM	artxtype, #arvaltax
		WHERE	#arvaltax.tax_type_code = artxtype.tax_type_code
		
		INSERT	#ewerror
		(	module_id, 		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20246,
			tax_type_code,	"",			0,
			0.0,			1,		trx_ctrl_num,
			sequence_id,		"",			0				
		FROM	#arvaltax
		WHERE	temp_flag = 0
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20247 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20247,
			"",			"",			0,
			amt_taxable,		4,		trx_ctrl_num,
			sequence_id,		"",			0				
		FROM	#arvaltax
		WHERE	((amt_taxable) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20248 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20248,
			"",			"",			0,
			amt_gross,		4,		trx_ctrl_num,
			sequence_id,		"",			0				
		FROM	#arvaltax
		WHERE	((amt_gross) < (0.0) - 0.0000001)
	END
	
	
	IF (	SELECT e_level 
		FROM 	aredterr 
		WHERE 	e_code = 20249 ) >= @error_level
	BEGIN
		INSERT	#ewerror
		(	module_id, 		err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20249,
			"",			"",			0,
			amt_tax,		4,		trx_ctrl_num,
			sequence_id,		"",			0				
		FROM	#arvaltax
		WHERE	((amt_tax) < (0.0) - 0.0000001)
	END

	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvtd.sp" + ", line " + STR( 160, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateTaxDetail_SP] TO [public]
GO
