SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[imarvalh_sp]			@trx_type	smallint,
					@debug_level	smallint = 0
                                        
AS



	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 51, 5 ) + " -- ENTRY: "

	IF @trx_type = 2031
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 58, 5 ) + " -- MSG: " + "Validate for not empty Document Number and printed flag = 1"
			
		


		INSERT	#ewerror
		SELECT 2000,
		  	20950,
			doc_ctrl_num,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg
		WHERE 	printed_flag = 1 AND LTRIM(RTRIM(ISNULL(doc_ctrl_num, ""))) = ""


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 79, 5 ) + " -- MSG: " + "Validate for empty Document Number and printed flag = 0"

		INSERT	#ewerror
		SELECT 2000,
		  	20951,
			doc_ctrl_num,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM 	#arvalchg
		WHERE 	printed_flag = 0 AND (LTRIM(RTRIM(ISNULL(doc_ctrl_num,""))) <> "")
	END

	
	IF @trx_type = 2032
	BEGIN

		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 104, 5 ) + " -- MSG: " + "Validate apply_trx_type should only allow 2031"

		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20952,
			"",			"",			user_id,
			0.0,			2,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	(apply_trx_type <> 2031 AND apply_trx_type <> 0) OR LTRIM(RTRIM(ISNULL(apply_trx_type, ""))) = ""


		



		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 124, 5 ) + " -- MSG: " + "Validate on account credit memos must come with both appy_to_num and apply_trx_type"		

		INSERT	#ewerror
		(	module_id, 					err_code,		
			info1,			info2,			infoint,
			infofloat,		flag1,			trx_ctrl_num,
			sequence_id,		source_ctrl_num,	extra
		)
		SELECT 2000,			20953,
			"",			"",			user_id,
			0.0,			2,		trx_ctrl_num,
			0,			"",			0				
		FROM	#arvalchg
		WHERE	(LTRIM(RTRIM(ISNULL(apply_trx_type,""))) = 0 AND LTRIM(RTRIM(ISNULL(apply_to_num,""))) <> "")
			OR (LTRIM(RTRIM(ISNULL(apply_to_num, ""))) = "" AND LTRIM(RTRIM(ISNULL(apply_trx_type,""))) <> 0)

	END

	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "imarvalh.sp" + ", line " + STR( 143, 5 ) + " -- EXIT: "
GO
GRANT EXECUTE ON  [dbo].[imarvalh_sp] TO [public]
GO
