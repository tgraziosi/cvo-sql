SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[ARCMValidateRefCode_SP]	@error_level	smallint,
					@debug_level	smallint = 0
AS

DECLARE	
	@result		smallint,
	@rule_flag		smallint


BEGIN
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvrc.sp" + ", line " + STR( 42, 5 ) + " -- ENTRY: "
	
	SELECT	@rule_flag = 0
	
	SELECT @rule_flag = SIGN(SIGN(e_level-@error_level)+1)
	FROM	aredterr
	WHERE	e_code = 20250
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 2
	FROM	aredterr
	WHERE	e_code = 20255
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 4
	FROM	aredterr
	WHERE	e_code = 20257
	
	SELECT @rule_flag = @rule_flag + SIGN(SIGN(e_level-@error_level)+1) * 8
	FROM	aredterr
	WHERE	e_code = 20256
	
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
		SELECT	trx_ctrl_num,		sequence_id,		gl_rev_acct,
			reference_code,	0
		FROM	#arvalcdt
		
		EXEC @result = ARValidateREFerenceCode_SP	@rule_flag,
								2032,
								@debug_level
		
		IF( @result != 0 )
		BEGIN
			RETURN @result
		END	

		DROP TABLE #aractref
	END

	RETURN 0			 	
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/arcmvrc.sp" + ", line " + STR( 88, 5 ) + " -- EXIT: "
END
GO
GRANT EXECUTE ON  [dbo].[ARCMValidateRefCode_SP] TO [public]
GO
