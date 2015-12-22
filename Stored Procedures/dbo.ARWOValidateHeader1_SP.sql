SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARWOValidateHeader1_SP]		@error_level smallint, 
						@debug_level smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level_act	smallint,
	@e_level_cur	smallint,
        @ib_flag        smallint                


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovh1.cpp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "

	























	



SELECT @ib_flag = 0
SELECT @ib_flag = ib_flag 
FROM glco


UPDATE  #arvalpyt
SET     interbranch_flag = 1
FROM 	#arvalpyt a, #arvalpdt b 
WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
AND   	a.org_id <> b.org_id


IF @ib_flag > 0
BEGIN
        



        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovh1.cpp" + ", line " + STR( 90, 5 ) + " -- MSG: " + "Validate a relationship exists for all branches in an inter-branch trx in arvalpyt/arvalpdt"        

        UPDATE 	#arvalpdt
	SET 	temp_flag = 0

	UPDATE 	#arvalpdt
	SET 	temp_flag = 1
	FROM 	#arvalpyt a, #arvalpdt b, OrganizationOrganizationRel oor
	WHERE 	a.org_id = oor.controlling_org_id
	        AND 	b.org_id = oor.detail_org_id
		AND     a.trx_ctrl_num = b.trx_ctrl_num

	INSERT INTO #ewerror
	(       module_id,      err_code,       info1,
	        info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
        )
	SELECT 2000,  20708,	         a.org_id + " - " + b.org_id,
                b.org_id,         a.hold_flag,           0.0,
                1,                a.trx_ctrl_num,        b.sequence_id,
	        "",               0
	FROM 	#arvalpyt a, #arvalpdt b
	WHERE 	b.temp_flag2 = 0
		AND     a.trx_ctrl_num = b.trx_ctrl_num
                AND     a.org_id <> b.org_id
                AND a.interbranch_flag = 1

	



        IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovh1.cpp" + ", line " + STR( 122, 5 ) + " -- MSG: " + "Validate organization exists and is active in Header"

	UPDATE #arvalpyt
        SET temp_flag2 = 0
 
	UPDATE #arvalpyt
        SET temp_flag2 = 1
        FROM #arvalpyt a, Organization c
        WHERE a.org_id = c.organization_id
                AND c.active_flag = 1
        

        INSERT INTO #ewerror
	(       module_id,      err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,extra
	)
	SELECT 2000, 20710,  org_id,
	        "",             "",             0.0,
		1,              trx_ctrl_num,   0,
		"",             0        
        FROM #arvalpyt 
	WHERE temp_flag2 = 0
END



	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20700) >= @error_level
	BEGIN
		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovh1.cpp" + ", line " + STR( 155, 5 ) + " -- MSG: " + "Validate user id exists"

		UPDATE	#arvalpyt
		SET	temp_flag = 0
		
		UPDATE	#arvalpyt
		SET	temp_flag = 1
		FROM	ewusers_vw ew
		WHERE	#arvalpyt.user_id = ew.user_id
		

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
		FROM	#arvalpyt 
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



	SELECT	@e_level_act = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20704
	SELECT	@e_level_cur = SIGN(1 + SIGN(e_level - @error_level)) FROM aredterr WHERE e_code = 20705

	IF (@e_level_act + @e_level_cur) > 0 
	BEGIN
		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(ac.ar_acct_code,pyt.org_id),
			pyt.date_applied,
			pdt.inv_cur_code,
			20704,			
			@e_level_act,
			20705,
			@e_level_cur
		FROM	#arvalpyt pyt, #arvalpdt pdt, araccts ac
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.posting_code = ac.posting_code

		INSERT	#account
		SELECT pyt.trx_ctrl_num,
			dbo.IBAcctMask_fn(arwo.writeoff_account,pyt.org_id),
			pyt.date_applied,
			pdt.inv_cur_code,
			20704,			
			@e_level_act,
			20705,
			@e_level_cur 
		FROM	#arvalpyt pyt, #arvalpdt pdt, arwrofac arwo
		WHERE	pyt.trx_ctrl_num = pdt.trx_ctrl_num
		AND	pdt.writeoff_code = arwo.writeoff_code

	END
	
	



	EXEC @result = ARValidateACCounT_SP	@debug_level
	IF( @result != 0 )
	BEGIN
		RETURN @result
	END

	DROP TABLE #account


	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arwovh1.cpp" + ", line " + STR( 237, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARWOValidateHeader1_SP] TO [public]
GO
