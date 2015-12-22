SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[ARINValidateHeader2_SP]	@error_level	smallint,
						@trx_type	smallint,
						@debug_level	smallint = 0,
 @rec_inv smallint
AS

DECLARE	
	@result	smallint

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 45, 5 ) + " -- ENTRY: "

	
	IF @trx_type = 2031
	BEGIN
		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20015 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 57, 5 ) + " -- MSG: " + "Validate that the dest_zone_code exists in zone table"
			
			UPDATE	#arvalchg
			SET	temp_flag = 0
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			WHERE	( LTRIM(dest_zone_code) IS NULL OR LTRIM(dest_zone_code) = " " )
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			FROM	arzone a
			WHERE	#arvalchg.dest_zone_code = a.zone_code
			AND	#arvalchg.temp_flag = 0
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20015,
				dest_zone_code,
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
		

		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20016 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 97, 5 ) + " -- MSG: " + "Validate that the comment code exists in comment table"
			
			UPDATE	#arvalchg
			SET	temp_flag = 0
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			WHERE	( LTRIM(comment_code) IS NULL OR LTRIM(comment_code) = " " )
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			FROM	arcommnt a
			WHERE	#arvalchg.comment_code = a.comment_code
			AND	#arvalchg.temp_flag = 0
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20016,
				comment_code,
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
		

		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20017 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 137, 5 ) + " -- MSG: " + "Validate that the shipping terms FOB code exists in the FOB table"
			
			UPDATE	#arvalchg
			SET	temp_flag = 0
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			WHERE	( LTRIM(fob_code) IS NULL OR LTRIM(fob_code) = " " )
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			FROM	arfob a
			WHERE	#arvalchg.fob_code = a.fob_code
			AND	#arvalchg.temp_flag = 0
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20017,
				fob_code,
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
		

		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20018 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 177, 5 ) + " -- MSG: " + "Validate that the freight code has defined freight rates"
			
			UPDATE	#arvalchg
			SET	temp_flag = 0
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			WHERE	( LTRIM(freight_code) IS NULL OR LTRIM(freight_code) = " " )
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			FROM	arfrate a
			WHERE	#arvalchg.freight_code = a.freight_code
			AND	#arvalchg.temp_flag = 0
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20018,
				freight_code,
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
	
		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20022 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 216, 5 ) + " -- MSG: " + "Validate that the cycle code exists in the cycle table"
			
			UPDATE	#arvalchg
			SET	temp_flag = 0
			
			UPDATE	#arvalchg
			SET	temp_flag = 1
			FROM	arcycle b
		 	WHERE	( #arvalchg.recurring_code = b.cycle_code
		 		AND #arvalchg.recurring_flag = 1 )
			OR	#arvalchg.recurring_flag = 0
			
			INSERT	#ewerror
			SELECT 2000,
			 	20022,
				recurring_code,
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
		
		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20023 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 251, 5 ) + " -- MSG: " + "Validate that the period type exists in the cycle table"
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20023,
				a.recurring_code + "--" + STR(b.cycle_type, 6, 0),
				"",
				0,
				0.0,
				1,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM 	#arvalchg a, arcycle b
		 	WHERE 	a.recurring_code = b.cycle_code
			AND	(b.cycle_type < 0 OR b.cycle_type > 7)
		END


		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20024 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 279, 5 ) + " -- MSG: " + "Validate that the cycle code is valid for an invoice"
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20024,
				a.recurring_code + "--" + STR(b.use_type, 6, 0),
				"",
				0,
				0.0,
				1,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM 	#arvalchg a, arcycle b
		 	WHERE 	a.recurring_code = b.cycle_code
			AND	(b.use_type < 1 OR b.use_type > 1)
		END


		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20025 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 307, 5 ) + " -- MSG: " + "Validate that the cycle code exists for this invoice while the recurring checkbox is set"
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20025,
				"",
				"",
				recurring_flag,
				0.0,
				2,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM 	#arvalchg 
		 	WHERE 	( LTRIM(recurring_code) IS NULL OR LTRIM(recurring_code) = " " ) 
			AND	recurring_flag = 1
		END


		
		IF ( SELECT e_level FROM aredterr WHERE e_code = 20026 ) >= @error_level
		BEGIN
			IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 335, 5 ) + " -- MSG: " + "Validate that the recurring checkbox is set while a cycle code exists "
			
			
			INSERT	#ewerror
			SELECT 2000,
			 	20026,
				recurring_code,
				"",
				0,
				0.0,
				1,
				trx_ctrl_num,
				0,
				ISNULL(source_trx_ctrl_num, ""),
				0
			FROM 	#arvalchg a, arcycle b
		 	WHERE 	a.recurring_code = b.cycle_code
			AND	a.recurring_flag = 0
		END

	END

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20019 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 364, 5 ) + " -- MSG: " + "Validate that the terms code exists in terms table"
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(terms_code) IS NULL OR LTRIM(terms_code) = " " )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arterms a
		WHERE	#arvalchg.terms_code = a.terms_code
		AND	#arvalchg.temp_flag = 0
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20019,
			terms_code,
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
	

	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20020 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 404, 5 ) + " -- MSG: " + "Validate that the fin_chg_code exists in the finance late charge table"
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		WHERE	( LTRIM(fin_chg_code) IS NULL OR LTRIM(fin_chg_code) = " " )
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	arfinchg a
		WHERE	#arvalchg.fin_chg_code = a.fin_chg_code
		AND	#arvalchg.temp_flag = 0
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20020,
			fin_chg_code,
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
	
	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20027 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 443, 5 ) + " -- MSG: " + "Validate that the tax code on the invoice header exists in the tax code table"
		
		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	artax a
		WHERE	#arvalchg.tax_code = a.tax_code
		
		
		INSERT	#ewerror
		SELECT 2000,
		 	20027,
			tax_code,
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
		
	
	IF ( SELECT e_level FROM aredterr WHERE e_code = 20028 ) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 478, 5 ) + " -- MSG: " + "Validate that the posted flag is set to valid state"

		
		INSERT	#ewerror
		SELECT 2000,
		 	20028,
			"",
			"",
			posted_flag,
			0.0,
			2,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg
	 	WHERE	posted_flag < -1 OR posted_flag > 0
	END


	
	IF ( ( SELECT e_level FROM aredterr WHERE e_code = 20030 ) >= @error_level )
 AND @rec_inv = 0
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 506, 5 ) + " -- MSG: " + "Check if this transaction is currently on hold"

		
		INSERT	#ewerror
		SELECT 2000,
		 	20030,
			"",
			"",
			hold_flag,
			0.0,
			2,
			trx_ctrl_num,
			0,
			ISNULL(source_trx_ctrl_num, ""),
			0
		FROM	#arvalchg
	 	WHERE	hold_flag = 1
	END

	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arinvh2.sp" + ", line " + STR( 528, 5 ) + " -- EXIT: "
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[ARINValidateHeader2_SP] TO [public]
GO
