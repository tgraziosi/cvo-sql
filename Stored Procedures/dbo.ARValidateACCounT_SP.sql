SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[ARValidateACCounT_SP]	@debug_level smallint = 0
AS

DECLARE	
	@result	smallint,
	@e_level	smallint


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvacct.sp" + ", line " + STR( 34, 5 ) + " -- ENTRY: "

	
	
CREATE TABLE #validate_acct (
				trx_ctrl_num	varchar(16),
				account_code	varchar(32),
				date_applied	int,
				currency_code	varchar(8),
				err_code_act	int,
				active_check	smallint,
				err_code_cur	int,
				cur_check	smallint
					)
create index #validate_acct1 on #validate_acct (account_code,currency_code,active_check)  --ggr
	
	INSERT	#validate_acct
	SELECT DISTINCT	trx_ctrl_num,
				account_code,
				date_applied,
				currency_code,
				err_code_act,
				active_check,
				err_code_cur,
				cur_check
	FROM	#account
	

	CREATE TABLE #glchart_temp (
				account_code	varchar(32),
				currency_code	varchar(8) NULL,
				active_date	int NULL,
				inactive_date	int NULL,
				inactive_flag	smallint NULL
					)
	create index #glchart_temp1 on #glchart_temp (account_code,currency_code,active_date)  --ggr
	
	INSERT	#glchart_temp	(account_code)
	SELECT DISTINCT account_code
	FROM	#validate_acct
	
	UPDATE	#glchart_temp
	SET	currency_code = gl.currency_code,
		active_date = gl.active_date,
		inactive_date = gl.inactive_date,
		inactive_flag = gl.inactive_flag
	FROM	glchart gl
	WHERE	#glchart_temp.account_code = gl.account_code
	

	
	UPDATE	#validate_acct
	SET	active_check = 2
	FROM	#validate_acct a, #glchart_temp gl
	WHERE	a.active_check = 1
	AND	a.account_code = gl.account_code
	AND	gl.active_date IS NULL

	
	UPDATE	#validate_acct
	SET	active_check = 2
	FROM	#validate_acct a, #glchart_temp gl
	WHERE	a.active_check = 1
	AND	a.account_code = gl.account_code
	AND	(gl.inactive_flag = 1
	OR	(a.date_applied < gl.active_date
	AND	gl.active_date != 0)
	OR	(a.date_applied > gl.inactive_date
	AND	gl.inactive_date != 0))

	
	UPDATE	#validate_acct
	SET	cur_check = 2
	FROM	#validate_acct a, #glchart_temp gl
	WHERE	a.cur_check = 1
	AND	a.account_code = gl.account_code
	AND	( LTRIM(gl.currency_code) IS NOT NULL AND LTRIM(gl.currency_code) != " " )
	AND	a.currency_code != gl.currency_code
	
	
	INSERT #ewerror
	SELECT	2000,
		a.err_code_act,
		a.account_code,
		"",
		0,
		0.0,
		1,
		a.trx_ctrl_num,
		0,
		"",
		0
	FROM	#validate_acct a
	WHERE	a.active_check = 2
		
	
	INSERT #ewerror
	SELECT	2000,
		a.err_code_cur,
		a.account_code,
		"",
		0,
		0.0,
		1,
		a.trx_ctrl_num,
		0,
		"",
		0
	FROM	#validate_acct a
	WHERE	a.cur_check = 2


	DROP TABLE #glchart_temp
	DROP TABLE #validate_acct
	
	RETURN 0
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arvacct.sp" + ", line " + STR( 186, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARValidateACCounT_SP] TO [public]
GO
