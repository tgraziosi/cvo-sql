SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARIAValidateDetail_SP]	@error_level	smallint,
					@debug_level	smallint = 0
AS

DECLARE	
	@result		smallint,
	@rule_flag	smallint,
        @ib_flag        smallint                

BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavd.cpp" + ", line " + STR( 48, 5 ) + " -- ENTRY: "
	
	SELECT	@rule_flag = 0
	
	SELECT @rule_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20806
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 2
	FROM	aredterr
	WHERE	e_code = 20807
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 4
	FROM	aredterr
	WHERE	e_code = 20809
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 8
	FROM	aredterr
	WHERE	e_code = 20808

	

        SELECT 	@ib_flag = 0
	SELECT 	@ib_flag = ib_flag
	FROM 	glco

if(@ib_flag > 0)
BEGIN
        


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20811 ) >= @error_level
        BEGIN

                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavd.cpp" + ", line " + STR( 82, 5 ) + " -- MSG: " + "Validate if account mapping exists for detail"

	        UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

        	UPDATE 	#arvalcdt
		SET 	temp_flag2 = 1
        	FROM 	#arvalchg a, #arvalcdt b, OrganizationOrganizationDef ood
	        WHERE 	a.org_id = ood.controlling_org_id
		AND 	b.org_id = ood.detail_org_id
        	AND 	b.gl_rev_acct LIKE ood.account_mask			

	INSERT INTO #ewerror
	(   module_id,      	err_code,       info1,
		info2,          infoint,        infofloat,
		flag1,          trx_ctrl_num,   sequence_id,
		source_ctrl_num,	extra
	)
	SELECT 2000, 20811, b.gl_rev_acct,
		b.org_id, user_id, 0.0,
		0, b.trx_ctrl_num, b.sequence_id,
		b.trx_ctrl_num, 0
	FROM 	#arvalcdt b, #arvalchg a
	WHERE 	b.trx_ctrl_num = a.trx_ctrl_num
	AND	b.sequence_id > -1
        AND     a.org_id <> b.org_id
	AND 	b.temp_flag2 = 0
	END

	


	IF ( SELECT e_level FROM aredterr WHERE e_code = 20101 ) >= @error_level
	BEGIN

                IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavd.cpp" + ", line " + STR( 117, 5 ) + " -- MSG: " + "Validate organization exists and is active in Detail"

		UPDATE 	#arvalcdt
	        SET 	temp_flag2 = 0

		UPDATE 	#arvalcdt
		SET 	temp_flag2 = 1
		FROM 	#arvalcdt a, Organization o
		WHERE 	a.org_id = o.organization_id
		AND 	o.active_flag = 1


		INSERT INTO #ewerror
		(       module_id,      err_code,       info1,
			info2,          infoint,        infofloat,
			flag1,          trx_ctrl_num,   sequence_id,
			source_ctrl_num,extra
		)
		SELECT 2000, 20813, b.org_id,
			b.org_id, "", 0.0,
			0, b.trx_ctrl_num, b.sequence_id,
			b.trx_ctrl_num, 0
		FROM 	#arvalchg a, #arvalcdt b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		AND	b.sequence_id > -1
		AND 	b.temp_flag2 = 0
	END

	



	IF (SELECT e_level FROM aredterr WHERE e_code = 20814) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavd1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate account code for organization \ariavd"

		


		UPDATE 	#arvalcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalcdt
	        SET 	temp_flag = 1
		FROM 	#arvalcdt a
		WHERE  dbo.IBOrgbyAcct_fn(a.gl_rev_acct)  = a.org_id 

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20814, 		a.gl_rev_acct,
			a.org_id, 		0, 			0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a
		WHERE 	a.temp_flag = 0
	END

END	--end of ib_flag = 1


ELSE
BEGIN
	


	IF (SELECT e_level FROM aredterr WHERE e_code = 20815) >= @error_level
	BEGIN
		


		IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "arinvd1.cpp" + ", line " + STR( 126, 5 ) + " -- MSG: " + "Validate all organizations are the same \arinvd1"
		


		UPDATE 	#arvalcdt
	        SET 	temp_flag = 0

		



		UPDATE 	#arvalcdt
	        SET 	temp_flag = 1
		FROM 	#arvalcdt a, #arvalchg b
		WHERE 	a.trx_ctrl_num = b.trx_ctrl_num
		ANd	a.trx_type = b.trx_type
		AND 	a.org_id = b.org_id

		




		INSERT INTO #ewerror
		(       module_id,      	err_code,       	info1,
			info2,          	infoint,        	infofloat,
			flag1,          	trx_ctrl_num,   	sequence_id,
			source_ctrl_num,	extra
		)
		SELECT 	2000, 20815, 		b.org_id +'-'+ a.org_id,
			a.org_id, 		0, 			0.0,
			0, 			a.trx_ctrl_num, 	a.sequence_id,
			'', 			0
		FROM 	#arvalcdt a, #arvalchg b
		WHERE	a.trx_ctrl_num = b.trx_ctrl_num
		AND	a.temp_flag = 0
	END	
END
	IF ( @rule_flag > 0 )
	BEGIN
		
CREATE TABLE #aractref
(
	trx_ctrl_num		varchar(16),
	sequence_id 		int,
	account_code		varchar(32),
	reference_code	varchar(32)	NULL,
	temp_flag		smallint
)

		
		INSERT #aractref
		( 	
			trx_ctrl_num,		sequence_id,		account_code,
		     	reference_code,	temp_flag		
		)	
		SELECT	trx_ctrl_num,		sequence_id,		new_gl_rev_acct,
			new_reference_code,	0
		FROM	#arvalcdt
		
		EXEC @result = ARValidateREFerenceCode_SP	@rule_flag,
								2051,
								@debug_level
		
		IF( @result != 0 )
		BEGIN
			RETURN @result
		END	

		DROP TABLE #aractref
	END

	RETURN 0			      	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "ariavd.cpp" + ", line " + STR( 268, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARIAValidateDetail_SP] TO [public]
GO
