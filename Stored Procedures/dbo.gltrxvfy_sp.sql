SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE        [dbo].[gltrxvfy_sp]
						@journal_ctrl_num       varchar(16) = NULL,
						@debug_level                  smallint = 0
			
AS
BEGIN

	DECLARE         @result                 int,
			@work_time              datetime,
			@start_time             datetime,
			@home_currency_code     varchar(8),
			@oper_currency_code	varchar(8),
			@home_prec		smallint,
			@oper_prec		smallint,
			@translation_rounding_acct varchar(32),
			@balance_home float,
			@balance_oper float,
			@sq_id int,
			@company_code varchar(8),
			@rate_type_home varchar(8),
			@rate_type_oper varchar(8),
			@trx_type smallint,
			@natural_balance	numeric,
			@str_msg		varchar(255)

	DECLARE		@org_id varchar(30)

			
	IF ( @debug_level > 1 )
	BEGIN
		SELECT  "*****************  Entering gltrxvfy_sp ******************"
		SELECT  "Journal No.        : "+@journal_ctrl_num
		SELECT  "Debug Level        : "+convert(char(10), @debug_level )
		SELECT  @work_time = getdate(), @start_time = getdate()
	END
		
	


	SELECT  @home_currency_code = home_currency,
		@oper_currency_code = oper_currency,
		@translation_rounding_acct = translation_rounding_acct,
		@company_code = company_code,
		@rate_type_home = rate_type_home,
		@rate_type_oper = rate_type_oper,
		@balance_home = 0.0,
		@balance_oper = 0.0
	FROM    glco
	


	SELECT  @home_prec = curr_precision
	FROM    glcurr_vw
	WHERE   currency_code = @home_currency_code

	SELECT  @oper_prec = curr_precision
	FROM    glcurr_vw
	WHERE   currency_code = @oper_currency_code

	IF ( @home_prec IS NULL OR @oper_prec IS NULL )
	BEGIN
		INSERT  #trxerror ( journal_ctrl_num,  sequence_id,  error_code )
		SELECT  @journal_ctrl_num, -1, 1050
		
		RETURN 1050
	END






	SELECT	@natural_balance = 0.0
	SELECT	@natural_balance = ABS(SUM(nat_balance))
	FROM	#gltrxdet
	WHERE	journal_ctrl_num = @journal_ctrl_num
	
	IF (((@natural_balance) > (0.0) + 0.0000001))
	BEGIN
		IF ( @debug_level > 0 )
		BEGIN
			SELECT "natural_balance = " + STR(@natural_balance,30,6)
			SELECT	"*** gltrxvfy_sp - Natural Balance - Out Of Balance"
		END
		INSERT  #trxerror ( journal_ctrl_num,  sequence_id,  error_code )
		SELECT  @journal_ctrl_num, -1, 1013

		RETURN 1013
	END

	IF ( @debug_level > 1 )
	BEGIN 
		SELECT "GLTRXVFY - Details From #GLTRXDET"
		SELECT convert(char(25), @oper_prec)
		SELECT  convert( char(20), journal_ctrl_num )+
			convert( char(35), rate_oper )+
			convert( char(35), balance_oper ) +
			convert( char(35), balance )
		FROM 	#gltrxdet
	END

	SELECT	@balance_home = -SUM((SIGN((balance)) * ROUND(ABS((balance)) + 0.0000001, @home_prec))),
		@balance_oper = -SUM((SIGN((balance_oper)) * ROUND(ABS((balance_oper)) + 0.0000001, @oper_prec))),
		@trx_type = MAX(trx_type)
	FROM	#gltrxdet
	 
	SELECT @balance_home = ISNULL(@balance_home,0.0),
		@balance_oper = ISNULL(@balance_oper,0.0)

	IF ( @debug_level > 1 )
	BEGIN 
		SELECT "GLTRXVFY - Check balances"
		SELECT convert(char(25), @balance_home)
		SELECT convert(char(25), @balance_oper)
	END

	IF ((ABS((@balance_home)-(0.0)) < 0.0000001) AND (ABS((@balance_oper)-(0.0)) < 0.0000001))
		RETURN 0

	


	SELECT 	@org_id = org_id 
	FROM	#gltrx
	WHERE	journal_ctrl_num = @journal_ctrl_num	

	SELECT @translation_rounding_acct = dbo.IBAcctMask_fn(@translation_rounding_acct,@org_id)

	

	EXEC appgetstring_sp "STR_CURRENCY_TRANSLATION", @str_msg OUT

	EXEC @result = gltrxcrd_sp 	
					6000,
					2,
					@journal_ctrl_num,
					@sq_id OUTPUT,
					@company_code,
					@translation_rounding_acct,
					@str_msg,
					"",		
					"",
					"",
					@balance_home,
					0.0, 
					@home_currency_code,		
					0.0, 
					@trx_type,
					0,
					@balance_oper,
					0.0,
					@rate_type_home,
					@rate_type_oper,
					@debug_level,
					@org_id				

	




	RETURN @result

END

GO
GRANT EXECUTE ON  [dbo].[gltrxvfy_sp] TO [public]
GO
