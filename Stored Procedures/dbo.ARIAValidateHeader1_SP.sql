SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARIAValidateHeader1_SP]		@error_level smallint, 
						@debug_level smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level_act	smallint,
	@e_level_cur	smallint,
        @ib_flag        integer        


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

	

























SELECT @ib_flag = 0
SELECT @ib_flag = ib_flag FROM glco

IF @ib_flag > 0
BEGIN
        
UPDATE #arvalchg
        SET interbranch_flag = 1
        FROM #arvalchg a, #arvalcdt b
        WHERE a.trx_ctrl_num = b.trx_ctrl_num
                AND a.org_id <> b.org_id

        



        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 86, 5 ) + " -- MSG: " + "Validate a relationship exists for all branches in an inter-branch trx in arinpchg/arinpcdt"        

        UPDATE 	#arvalcdt
	SET 	temp_flag2 = 0

	UPDATE 	#arvalcdt
	SET 	temp_flag2 = 1
	FROM 	#arvalchg a, #arvalcdt b, OrganizationOrganizationRel oor
	WHERE 	a.org_id = oor.controlling_org_id
	        AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

	INSERT INTO #ewerror
	(       module_id,      err_code,       info1,
	        info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
        )
	SELECT 2000,  20098,	         a.org_id + " - " + b.org_id,
                b.org_id,         a.hold_flag,           0.0,
                0,                a.trx_ctrl_num,        b.sequence_id,
	        "",               0
	FROM 	#arvalchg a, #arvalcdt b
	WHERE 	a.interbranch_flag = 1
		AND 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
		AND   	a.org_id <> b.org_id

	



        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 118, 5 ) + " -- MSG: " + "Validate branch exists and is active in Header"

	UPDATE #arvalchg
        SET temp_flag2 = 0
 
	UPDATE #arvalchg        
        SET	temp_flag2 = 1
        FROM #arvalchg a, Organization c
        WHERE a.org_id = c.organization_id
                AND c.active_flag = 1
        

        INSERT INTO #ewerror
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT 2000, 20100,      org_id,
	        org_id,       user_id,          0.0,
		0,              trx_ctrl_num,   0,
		"",             0        
        FROM #arvalchg 
	WHERE temp_flag2 = 0

END

	
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20700) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 151, 5 ) + " -- MSG: " + "Validate user id exists"

		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	ewusers_vw ew
		WHERE	#arvalchg.user_id = ew.user_id
		

		INSERT #ewerror
		SELECT	2000,
			20700,
			"",
			"",
			user_id,
			0.0,
			5,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalchg 
		WHERE	temp_flag = 0
	END


	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20801) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 184, 5 ) + " -- MSG: " + "Validate the invoice being adjusted not exist in the posted table"

		UPDATE	#arvalchg
		SET	temp_flag = 0
		
		UPDATE	#arvalchg
		SET	temp_flag = 1
		FROM	#arvalchg chg,  artrx trx
		WHERE	chg.apply_to_num = trx.doc_ctrl_num
		AND	chg.apply_trx_type = trx.trx_type
		
		INSERT #ewerror
		SELECT	2000,
			20801,
			apply_to_num,
			"",
			0,
			0.0,
			0,
			trx_ctrl_num,
			0,
			"",
			0
		FROM	#arvalchg
		WHERE	temp_flag = 0
	END

	




	
CREATE TABLE #account (
				trx_ctrl_num	varchar(16),
				account_code	varchar(32),
				date_applied	int,
				currency_code	varchar(8),
				err_code_act	int,
				active_check	smallint,
				err_code_cur	int,
				cur_check	smallint
					)



	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20803
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20805

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT cdt.trx_ctrl_num,
			cdt.gl_rev_acct,
			chg.date_applied,
			chg.nat_cur_code,
			20803,			
			@e_level_act,
			20805,
			@e_level_cur
		FROM	#arvalchg chg, #arvalcdt cdt
		WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num

	END
	
	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20802
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20804

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT cdt.trx_ctrl_num,
			cdt.new_gl_rev_acct,
			chg.date_applied,
			chg.nat_cur_code,
			20802,			
			@e_level_act,
			20804,
			@e_level_cur
		FROM	#arvalchg chg, #arvalcdt cdt
		WHERE	chg.trx_ctrl_num = cdt.trx_ctrl_num

	END
	
	



	EXEC @result = ARValidateACCounT_SP	@debug_level
	IF( @result != 0 )
	BEGIN
		RETURN @result
	END

	DROP TABLE #account


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavh1.cpp" + ", line " + STR( 271, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARIAValidateHeader1_SP] TO [public]
GO
