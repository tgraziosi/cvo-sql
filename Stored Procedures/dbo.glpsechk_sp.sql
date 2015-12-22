SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

		
CREATE PROCEDURE	[dbo].[glpsechk_sp] 
			@batch_code		varchar(16),
			@home_company_code	varchar(8),
			@rec_company_code	varchar(8),
			@debug_level		smallint = 0

AS

BEGIN 
	DECLARE		@home_currency_code	varchar(8),
			@no_trans		int,
			@prec			smallint,
			@rounding_factor	float,
			@work_time		datetime,
 @start_time datetime,
 @oper_currency_code varchar(8),
 @prec_oper smallint,
 @rounding_factor_oper float
	IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/glpsechk.sp" + ", line " + STR( 125, 5 ) + " -- ENTRY: "
	SELECT	@work_time = getdate(), @start_time = getdate()

	
	IF ( @home_company_code = @rec_company_code )
	BEGIN
		
		SELECT	@home_currency_code = home_currency
		FROM	glco
 
 SELECT @oper_currency_code = oper_currency
 FROM glco
		
		SELECT	@rounding_factor = rounding_factor,
			@prec = curr_precision
		FROM	glcurr_vw
		WHERE	currency_code = @home_currency_code

		IF ( @rounding_factor IS NULL OR @prec IS NULL )
		BEGIN
		 	RETURN 1050
					 
		END
 
 SELECT @rounding_factor_oper = rounding_factor,
 @prec_oper = curr_precision
		FROM	glcurr_vw
 WHERE currency_code = @oper_currency_code

 IF ( @rounding_factor_oper IS NULL OR @prec_oper IS NULL )
		BEGIN
 
 RETURN 1050 
 END
		
		
		INSERT		#hold
		SELECT		journal_ctrl_num, 1013, 0
		FROM		#gldtrdet
		GROUP BY	journal_ctrl_num 
		HAVING	 	ABS(SUM(ROUND(balance, @prec))) >= @rounding_factor

		IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 186, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for out of balance transaction"
 
		
		
		
		UPDATE	#gldtrdet
		SET	mark_flag = 1
		FROM	#gldtrdet d, glcurr_vw c
		WHERE	d.nat_cur_code = c.currency_code
		
		INSERT	#hold
		SELECT	DISTINCT journal_ctrl_num, 1009, 0
		FROM	#gldtrdet
		WHERE	mark_flag = 0
		
		UPDATE	#gldtrdet
		SET	mark_flag = 0
		WHERE	mark_flag = 1

		IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 222, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for invalid currency codes"

		
 INSERT #hold 
		SELECT		journal_ctrl_num, 3025, 0
		FROM		#gldtrdet
		WHERE		balance_oper IS NULL

 IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 232, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for operational balance"
	END
	
	
	UPDATE	#gldtrdet
	SET	mark_flag = 1
	FROM	#gldtrdet d, glchart c
	WHERE	d.account_code = c.account_code
	AND	d.rec_company_code = @rec_company_code
	
	INSERT	#hold
	SELECT	DISTINCT journal_ctrl_num, 1007, 0
	FROM	#gldtrdet d
	WHERE	mark_flag = 0
	AND	d.rec_company_code = @rec_company_code

	UPDATE	#gldtrdet
	SET	mark_flag = 0
	WHERE	mark_flag = 1

	IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 262, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for invalid account codes"
	
	

	UPDATE	#gldtrx
	SET	mark_flag = 1
	FROM	#gldtrx h, glprd p
	WHERE	h.date_applied 
	BETWEEN	p.period_start_date AND p.period_end_date

	INSERT	#hold
	SELECT	journal_ctrl_num, 1062, 0
	FROM	#gldtrx
	WHERE	mark_flag = 0
	
	UPDATE	#gldtrx
	SET	mark_flag = 0
	WHERE	mark_flag = 1

	IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 290, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for invalid apply dates"
	
	
	UPDATE	#gldtrx
	SET	mark_flag = 1
	FROM	#gldtrx h, glprd p, glprd q
	WHERE	(h.repeating_flag = 1 
	OR	h.reversing_flag = 1
	OR	h.recurring_flag = 1)
	AND	h.date_applied
	BETWEEN	p.period_start_date AND p.period_end_date
	AND	p.period_end_date < q.period_end_date

	
	INSERT	#hold
	SELECT	journal_ctrl_num, 1040, 0
	FROM	#gldtrx
	WHERE	(repeating_flag = 1
	OR	reversing_flag = 1
	OR	recurring_flag = 1)
	AND	mark_flag = 0
	
	UPDATE	#gldtrx
	SET	mark_flag = 0
	WHERE	mark_flag = 1

	IF ( @debug_level > 2 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 325, 5 ) + " -- MSG: " + CONVERT(char,@work_time,100) + "Checking for existence of next period for repeating and reversing transactions"

	IF ( @debug_level > 1 ) SELECT "tmp/glpsechk.sp" + ", line " + STR( 327, 5 ) + " -- MSG: " + CONVERT(char,@start_time,100) + " "

	
	IF EXISTS(	SELECT	*
			FROM	#hold )
	BEGIN
		IF ( @debug_level > 1 )
		BEGIN
			SELECT	"*** glpsechk_sp - Errors Found!"
			SELECT	convert( char(20), "journal_ctrl_num" )+
				convert( char(15), "e_code" )
			SELECT	convert( char(20), journal_ctrl_num )+
				convert( char(15), e_code )
			FROM	#hold
		END
		
		RETURN	202
	END

	ELSE	
	BEGIN
		IF ( @debug_level > 1 )
			SELECT	"*** glpsechk - No Errors Found!"
		RETURN 	0
	END
END

GO
GRANT EXECUTE ON  [dbo].[glpsechk_sp] TO [public]
GO
