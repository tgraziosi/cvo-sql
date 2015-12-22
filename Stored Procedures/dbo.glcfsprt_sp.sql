SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROC [dbo].[glcfsprt_sp] (
	@consol_ctrl_num	varchar(16),
	@journal_ctrl_num	varchar(16),
	@p_period_end_date	int,
	@p_prev_end_date	int,
	@s_currency		varchar(8),
	@p_currency		varchar(8),
	@next_seq_id		int,
	@company_code		varchar(8),
	@company_id		smallint,
	@trx_type		smallint,
	@acct_mask		varchar(35),
	@process_id  		int,
	@user_id 		smallint,
	@rate_type_home		varchar(8),
	@rate_type_oper		varchar(8), 
	@p_currency_oper		varchar(8))
AS




DECLARE	@cp_period_end_rate    	float,	
	@pp_period_end_rate    	float,	
	@rate_change		float,	
	@s_prev_start_date	int,	
	@s_prev_end_date	int,	
	@min_period_end_date int,									
	@min_account_code varchar(32),								
	@count_spot		int,
	@rec_num		int,
	@spot_count		int,
	@account_code		varchar(32),
	@curr_account		varchar(32),
	@consol_acct		varchar(32),
	@nat_balance		float,
	@seg1_code		varchar(32),
	@seg2_code		varchar(32),
	@seg3_code		varchar(32),
	@seg4_code		varchar(32),
	@db_name		varchar(128),
	@sub_comp_id		smallint,
	@owner_percent		float,
	@c_override_rate 	float,
	@p_override_rate	float,
	@c_override_rate_oper 	float,
	@p_override_rate_oper	float,
	@pp_override_rate_oper	float,
	@pp_override_rate	float,
	@balance		float,
	@balance_oper		float,
	@rounding_factor	float,
	@precision		smallint,
	@rounding_factor_oper	float,
	@precision_oper		smallint,
	@cur_rate_change	float,
	@cur_rate_change_oper	float,
	@SPOT_RATE		smallint,
	@CONSOL_TRX		smallint,
	@RETAIN_EARNING		smallint,
	@INCOME_SUMMARY		smallint,
	@cp_period_end_rate_oper    	float,	
	@pp_period_end_rate_oper    	float,	
	@rate_change_oper		float	




SELECT	@SPOT_RATE = 3, @CONSOL_TRX = 121, @RETAIN_EARNING = 350,
	@INCOME_SUMMARY = 600




SELECT	@sub_comp_id = b.company_id,
	@db_name = db_name
FROM	glcomp_vw a, glco b
WHERE	a.company_code = b.company_code
AND	a.company_id = b.company_id




SELECT	@owner_percent = owner_percent
FROM	glcocon_vw
WHERE	parent_comp_id = @company_id
AND	sub_comp_id = @sub_comp_id




SELECT	@rounding_factor = rounding_factor,
	@precision = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @p_currency

SELECT	@rounding_factor_oper = rounding_factor,
	@precision_oper = curr_precision
FROM	glcurr_vw
WHERE	currency_code = @p_currency_oper




SELECT 	@rec_num = 0, @spot_count = 0, @curr_account = "", 
	@c_override_rate = NULL, @c_override_rate_oper = NULL

CREATE TABLE #spot_detail (
	account_code		varchar(32)	NOT NULL,
	current_balance		float 		NOT NULL
	)




EXEC	CVO_Control..mccurcvt_sp
	@apply_date = @p_period_end_date,
	@rate_applied = 1,
	@from_currency = @s_currency,
	@from_amount = 1,
	@to_currency = @p_currency,
	@rate_type = @rate_type_home,
	@to_amount = 1,
	@rate_used = @cp_period_end_rate OUTPUT, 
	@return_row = 0
        IF      @p_currency = @p_currency_oper
                SELECT  @cp_period_end_rate_oper  = @cp_period_end_rate
        ELSE
        EXEC    CVO_Control..mccurcvt_sp
                @apply_date = @p_period_end_date,
                @rate_applied = 1,
                @from_currency = @s_currency,
                @from_amount = 1,
                @to_currency = @p_currency_oper,
		@rate_type = @rate_type_oper,
                @to_amount = 1,
                @rate_used = @cp_period_end_rate_oper OUTPUT,
                @return_row = 0



EXEC	CVO_Control..mccurcvt_sp
	@apply_date = @p_prev_end_date,
	@rate_applied = 1,
	@from_currency = @s_currency,
	@from_amount = 1,
	@to_currency = @p_currency,
	@rate_type = @rate_type_home,
	@to_amount = 1,
	@rate_used = @pp_period_end_rate OUTPUT, 
	@return_row = 0

EXEC	CVO_Control..mccurcvt_sp
	@apply_date = @p_prev_end_date,
	@rate_applied = 1,
	@from_currency = @s_currency,
	@from_amount = 1,
	@to_currency = @p_currency_oper,
	@rate_type = @rate_type_oper,
	@to_amount = 1,
	@rate_used = @pp_period_end_rate_oper OUTPUT, 
	@return_row = 0





	SELECT @cp_period_end_rate =  ( SIGN(1 + SIGN(@cp_period_end_rate))*(@cp_period_end_rate) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate,6))))/(@cp_period_end_rate + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate,6)))))) * SIGN(SIGN(@cp_period_end_rate) - 1) )
	SELECT @pp_period_end_rate =  ( SIGN(1 + SIGN(@pp_period_end_rate))*(@pp_period_end_rate) + (SIGN(ABS(SIGN(ROUND(@pp_period_end_rate,6))))/(@pp_period_end_rate + SIGN(1 - ABS(SIGN(ROUND(@pp_period_end_rate,6)))))) * SIGN(SIGN(@pp_period_end_rate) - 1) )
	SELECT @cp_period_end_rate_oper =  ( SIGN(1 + SIGN(@cp_period_end_rate_oper))*(@cp_period_end_rate_oper) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate_oper,6))))/(@cp_period_end_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate_oper,6)))))) * SIGN(SIGN(@cp_period_end_rate_oper) - 1) )
	SELECT @pp_period_end_rate_oper =  ( SIGN(1 + SIGN(@pp_period_end_rate_oper))*(@pp_period_end_rate_oper) + (SIGN(ABS(SIGN(ROUND(@pp_period_end_rate_oper,6))))/(@pp_period_end_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@pp_period_end_rate_oper,6)))))) * SIGN(SIGN(@pp_period_end_rate_oper) - 1) )

SELECT	@rate_change = @cp_period_end_rate - @pp_period_end_rate
SELECT	@rate_change_oper = @cp_period_end_rate_oper - @pp_period_end_rate_oper

IF	@rate_change = 0.0 AND @rate_change_oper = 0.0
BEGIN
	DROP TABLE #spot_detail

	SELECT 0
	RETURN
END




SELECT	@cur_rate_change = @rate_change, @cur_rate_change_oper = @rate_change_oper




SELECT	@s_prev_end_date = period_start_date - 1
FROM	glprd
WHERE	period_end_date = @p_period_end_date
AND	period_start_date = @p_prev_end_date + 1

IF	( @s_prev_end_date IS NULL )
BEGIN
	



	SELECT	@min_period_end_date = MIN( period_end_date )		
	FROM	glprd									
	WHERE	period_end_date >= @p_prev_end_date					
	
	SELECT	@s_prev_end_date = period_end_date,
		@s_prev_start_date = period_start_date
	FROM	glprd
	WHERE	period_end_date >= @p_prev_end_date
	  AND	period_end_date = @min_period_end_date				

	



	WHILE	( @s_prev_end_date - @p_prev_end_date ) >=
		( @p_prev_end_date - @s_prev_start_date )
	BEGIN
		SELECT	@s_prev_end_date = NULL

		



		SELECT	@s_prev_end_date = period_end_date,
			@s_prev_start_date = period_start_date
		FROM	glprd
		WHERE	period_end_date = @s_prev_start_date - 1

		



		IF @s_prev_end_date IS NULL
		BEGIN
			SELECT 0
			RETURN
		END
	END
END






IF NOT EXISTS ( SELECT * FROM #glbal WHERE balance_date = @s_prev_end_date )
BEGIN
	SELECT 0
	RETURN 
END





INSERT	#spot_detail
SELECT	b.account_code,	current_balance					
FROM	#glbal b, glchart s
WHERE	b.account_code = s.account_code
AND	b.balance_date = @s_prev_end_date
AND	s.consol_type = @SPOT_RATE
AND	s.account_type != @RETAIN_EARNING
AND	s.account_type != @INCOME_SUMMARY
GROUP BY b.account_code,current_balance	




SELECT	@count_spot = @@rowcount




WHILE 	@rec_num < @count_spot
BEGIN
	


	SELECT	@rate_change = @cur_rate_change,
		@c_override_rate = NULL, @p_override_rate = NULL

	SELECT	@rate_change_oper = @cur_rate_change_oper,
		@c_override_rate_oper = NULL, @p_override_rate_oper = NULL

	


	SELECT	@rec_num = @rec_num + 1

	


	SELECT	@min_account_code = MIN( account_code )				
	FROM	#spot_detail								
	WHERE	account_code > @curr_account						
	
	SELECT	@account_code = account_code,
		@nat_balance = current_balance 
	FROM	#spot_detail
	WHERE	account_code > @curr_account
	  AND	account_code = @min_account_code					

	SELECT	@curr_account = @account_code

	


	IF	@nat_balance = 0.0
		CONTINUE

	


	SET	rowcount 1
	SELECT	@consol_acct = NULL

	SELECT 	@consol_acct = consol_account 
	FROM 	glcocond_vw 
	WHERE	parent_comp_id = @company_id
	AND 	sub_comp_id = @sub_comp_id
	AND 	@account_code LIKE account_mask 
	ORDER BY sequence_id

	SET	rowcount 0

	


	IF	@consol_acct is NULL
		SELECT	@consol_acct = @account_code

	


	EXEC	glprsact_sp @consol_acct, @acct_mask, @seg1_code OUTPUT,
		@seg2_code OUTPUT, @seg3_code OUTPUT, @seg4_code OUTPUT

	


	IF	@seg1_code is NULL
		SELECT	@seg1_code = ""

	IF	@seg2_code is NULL
		SELECT	@seg2_code = ""

	IF	@seg3_code is NULL
		SELECT	@seg3_code = ""

	IF	@seg4_code is NULL
		SELECT	@seg4_code = ""

	



	EXEC glcfovsp_sp @sub_comp_id, @consol_acct, @p_prev_end_date, 3, 
	   @p_override_rate OUTPUT, @p_override_rate_oper OUTPUT

	EXEC glcfovsp_sp @sub_comp_id, @consol_acct, @p_period_end_date, 3, 
	   @c_override_rate OUTPUT, @c_override_rate_oper OUTPUT
	
	IF (@p_override_rate = 0.0)
		SELECT @p_override_rate = NULL
	IF (@p_override_rate_oper = 0.0)
		SELECT @p_override_rate_oper = NULL
	IF (@c_override_rate = 0.0)
		SELECT @c_override_rate = NULL
	IF (@c_override_rate_oper = 0.0)
		SELECT @c_override_rate_oper= NULL

	



	IF @c_override_rate IS NULL AND @p_override_rate IS NOT NULL
	BEGIN
		SELECT @cp_period_end_rate =  ( SIGN(1 + SIGN(@cp_period_end_rate))*(@cp_period_end_rate) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate,6))))/(@cp_period_end_rate + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate,6)))))) * SIGN(SIGN(@cp_period_end_rate) - 1) )
		SELECT @p_override_rate =  ( SIGN(1 + SIGN(@p_override_rate))*(@p_override_rate) + (SIGN(ABS(SIGN(ROUND(@p_override_rate,6))))/(@p_override_rate + SIGN(1 - ABS(SIGN(ROUND(@p_override_rate,6)))))) * SIGN(SIGN(@p_override_rate) - 1) )
		SELECT @rate_change = @cp_period_end_rate - @p_override_rate
	END
	ELSE IF @c_override_rate IS NOT NULL AND @p_override_rate IS NULL
	BEGIN
		SELECT @cp_period_end_rate =  ( SIGN(1 + SIGN(@cp_period_end_rate))*(@cp_period_end_rate) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate,6))))/(@cp_period_end_rate + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate,6)))))) * SIGN(SIGN(@cp_period_end_rate) - 1) )
		SELECT @pp_period_end_rate =  ( SIGN(1 + SIGN(@pp_period_end_rate))*(@pp_period_end_rate) + (SIGN(ABS(SIGN(ROUND(@pp_period_end_rate,6))))/(@pp_period_end_rate + SIGN(1 - ABS(SIGN(ROUND(@pp_period_end_rate,6)))))) * SIGN(SIGN(@pp_period_end_rate) - 1) )
		SELECT @rate_change = @c_override_rate - @pp_period_end_rate
	END
	
	ELSE IF @c_override_rate IS NOT NULL AND @p_override_rate IS NOT NULL
	BEGIN
		SELECT @c_override_rate =  ( SIGN(1 + SIGN(@c_override_rate))*(@c_override_rate) + (SIGN(ABS(SIGN(ROUND(@c_override_rate,6))))/(@c_override_rate + SIGN(1 - ABS(SIGN(ROUND(@c_override_rate,6)))))) * SIGN(SIGN(@c_override_rate) - 1) )
		SELECT @p_override_rate =  ( SIGN(1 + SIGN(@p_override_rate))*(@p_override_rate) + (SIGN(ABS(SIGN(ROUND(@p_override_rate,6))))/(@p_override_rate + SIGN(1 - ABS(SIGN(ROUND(@p_override_rate,6)))))) * SIGN(SIGN(@p_override_rate) - 1) )
		SELECT @rate_change = @c_override_rate - @p_override_rate
	END
	

	IF @c_override_rate_oper IS NULL AND @p_override_rate_oper IS NOT NULL
	BEGIN
		SELECT @cp_period_end_rate_oper =  ( SIGN(1 + SIGN(@cp_period_end_rate_oper))*(@cp_period_end_rate_oper) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate_oper,6))))/(@cp_period_end_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate_oper,6)))))) * SIGN(SIGN(@cp_period_end_rate_oper) - 1) )
		SELECT @p_override_rate_oper =  ( SIGN(1 + SIGN(@pp_override_rate_oper))*(@pp_override_rate_oper) + (SIGN(ABS(SIGN(ROUND(@pp_override_rate_oper,6))))/(@pp_override_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@pp_override_rate_oper,6)))))) * SIGN(SIGN(@pp_override_rate_oper) - 1) )
		SELECT @rate_change_oper = @cp_period_end_rate_oper - @p_override_rate_oper
	END
	ELSE IF @c_override_rate_oper IS NOT NULL AND @p_override_rate_oper IS NULL
	BEGIN
		SELECT @cp_period_end_rate_oper =  ( SIGN(1 + SIGN(@cp_period_end_rate_oper))*(@cp_period_end_rate_oper) + (SIGN(ABS(SIGN(ROUND(@cp_period_end_rate_oper,6))))/(@cp_period_end_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@cp_period_end_rate_oper,6)))))) * SIGN(SIGN(@cp_period_end_rate_oper) - 1) )
		SELECT @pp_period_end_rate_oper =  ( SIGN(1 + SIGN(@pp_period_end_rate_oper))*(@pp_period_end_rate_oper) + (SIGN(ABS(SIGN(ROUND(@pp_period_end_rate_oper,6))))/(@pp_period_end_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@pp_period_end_rate_oper,6)))))) * SIGN(SIGN(@pp_period_end_rate_oper) - 1) )
		SELECT @rate_change_oper = @c_override_rate_oper - @pp_period_end_rate_oper
	END
	
	ELSE IF @c_override_rate_oper IS NOT NULL AND @p_override_rate_oper IS NOT NULL
	BEGIN
		SELECT @c_override_rate_oper =  ( SIGN(1 + SIGN(@c_override_rate_oper))*(@c_override_rate_oper) + (SIGN(ABS(SIGN(ROUND(@c_override_rate_oper,6))))/(@c_override_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@c_override_rate_oper,6)))))) * SIGN(SIGN(@c_override_rate_oper) - 1) )
		SELECT @p_override_rate_oper =  ( SIGN(1 + SIGN(@p_override_rate_oper))*(@p_override_rate_oper) + (SIGN(ABS(SIGN(ROUND(@p_override_rate_oper,6))))/(@p_override_rate_oper + SIGN(1 - ABS(SIGN(ROUND(@p_override_rate_oper,6)))))) * SIGN(SIGN(@p_override_rate_oper) - 1) )
		SELECT @rate_change_oper = @c_override_rate_oper - @p_override_rate_oper
	END
	

	




	SELECT	@nat_balance = ( @nat_balance * @owner_percent ) / 100.0
	SELECT	@balance = @nat_balance * @rate_change,
		@balance_oper = @nat_balance * @rate_change_oper
	






	SELECT @balance = ROUND(@balance, @precision)
	SELECT @balance_oper = ROUND(@balance_oper, @precision_oper)

	


	EXEC glproclg_sp @process_id, @user_id, @CONSOL_TRX, @consol_ctrl_num, 
	   @journal_ctrl_num, '', @account_code, @consol_acct, @db_name, 
	   @rate_change, @nat_balance, @balance, @sub_comp_id, @SPOT_RATE, NULL,0,0,0,
	   @rate_change_oper, @balance_oper
	   
	


	
	SELECT @balance_oper = ISNULL(@balance_oper,0.0)
	SELECT @rate_change_oper = ISNULL(@rate_change_oper,0.0)

	INSERT	#glsprt (
		journal_ctrl_num,	sequence_id,	
		rec_company_code,	company_id,		
		account_code,		balance,		
		nat_balance,		nat_cur_code,
		rate,			seg1_code,
		seg2_code,		seg3_code,	
		seg4_code,		balance_oper,
		rate_oper,		rate_type_home,	rate_type_oper)
	VALUES	( @journal_ctrl_num,	@next_seq_id + @spot_count,
		@company_code,		@company_id,   		
		@consol_acct,		@balance,
		0.0,		@s_currency,
		@rate_change,		@seg1_code,
		@seg2_code,		@seg3_code,
		@seg4_code,		@balance_oper,
		@rate_change_oper,	@rate_type_home, @rate_type_oper)

	


	SELECT	@spot_count = @spot_count + 1
END





DROP TABLE #spot_detail
SELECT	next_seq_id = ( @next_seq_id + @spot_count )

RETURN

GO
GRANT EXECUTE ON  [dbo].[glcfsprt_sp] TO [public]
GO
