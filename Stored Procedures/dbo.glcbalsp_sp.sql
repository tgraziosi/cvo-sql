SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glcbalsp_sp] (
	@period		int,		 
	@p_period_end_date	int,	 
	@p_prev_end_date	int,	 
	@s_currency		varchar(8), 
	@p_currency		varchar(8),  
	@s_currency_oper	varchar(8), 
	@p_currency_oper	varchar(8), 
	@rate_type_home		varchar(8),  
	@rate_type_oper		varchar(8) ) 
AS
DECLARE @start_period 	int,		@s_prev_end_date int, 		
	@min_period_end_date int,									
	@s_prev_start_date int,		@curr_rate	float,
	@prev_rate	float,		@curr_rate_oper float, @prev_rate_oper float,
	@SPOT_RATE smallint,		@RETAIN_EARNING	smallint,	
	@INCOME_SUMMARY	smallint,	@YEAR_START smallint


SELECT	@SPOT_RATE = 3, @RETAIN_EARNING = 350, @INCOME_SUMMARY = 600,
	@YEAR_START = 1001


SELECT	@s_prev_end_date = period_start_date - 1
FROM	glprd
WHERE	period_end_date = @p_period_end_date
AND	period_start_date = @p_prev_end_date + 1


EXEC	CVO_Control..mccurcvt_sp @p_period_end_date, 1, @s_currency, 1,
	 @p_currency, @rate_type_home, 1, @curr_rate OUTPUT, 0

EXEC	CVO_Control..mccurcvt_sp @p_prev_end_date, 1, @s_currency, 1,
 	 @p_currency,	 @rate_type_home,1, @prev_rate OUTPUT, 0


EXEC	CVO_Control..mccurcvt_sp @p_period_end_date, 1, @s_currency_oper, 1,
	 @p_currency_oper, @rate_type_oper,1, @curr_rate_oper OUTPUT, 0

EXEC	CVO_Control..mccurcvt_sp @p_prev_end_date, 1, @s_currency_oper, 1,
 	 @p_currency_oper,@rate_type_oper, 1, @prev_rate_oper OUTPUT, 0



if	(@curr_rate = @prev_rate) AND	(@curr_rate_oper = @prev_rate_oper)
	RETURN 0


IF	( @s_prev_end_date IS NULL )
BEGIN
	
	SELECT @min_period_end_date = MIN( period_end_date )		
	FROM	glprd												
	WHERE	period_end_date >= @p_prev_end_date					

	SELECT	@s_prev_end_date = period_end_date,
		@s_prev_start_date = period_start_date
	FROM	glprd
	WHERE	period_end_date >= @p_prev_end_date
		AND period_end_date = @min_period_end_date				

	
	IF	@s_prev_end_date = @period OR @s_prev_end_date IS NULL
		RETURN 0

	WHILE	( @s_prev_end_date - @p_prev_end_date ) >=
		( @p_prev_end_date - @s_prev_start_date )
	BEGIN
		SELECT	@s_prev_end_date = NULL

		
		SELECT	@s_prev_end_date = period_end_date,
			@s_prev_start_date = period_start_date
		FROM	glprd
		WHERE	period_end_date = @s_prev_start_date - 1

		
		IF	@s_prev_end_date IS NULL
			RETURN 0
	END
END


IF	@s_prev_end_date = @period 
	RETURN 0


INSERT	#glbal (
	account_code,	balance_date,		debit,
	credit ,	net_change,		current_balance,	
	account_type,	consol_type,		detail_flag, net_change_oper, current_balance_oper)
SELECT	account_code,	@s_prev_end_date, 	0,		
	0,		0,			0,
	account_type,	consol_type,		consol_detail_flag, 0, 0.0
FROM	glchart 
WHERE 	consol_type = @SPOT_RATE 	
AND	account_type != @RETAIN_EARNING	
AND	account_type != @INCOME_SUMMARY	


SELECT	@start_period = MAX( period_end_date )
FROM	glprd
WHERE	period_end_date <= @s_prev_end_date
AND	period_type = @YEAR_START


DELETE #t1

INSERT	#t1 (
 account_code,	
	balance_date,	
	debit,
	credit,		
 net_change, 
 current_balance,
 net_change_oper, 
 current_balance_oper )
SELECT	b.account_code,						 
	@s_prev_end_date,
	SUM( b.home_debit ),
	SUM( b.home_credit ),
	SUM( b.home_net_change )*(1-ABS(SIGN(@s_prev_end_date-b.balance_date))),
 	SUM( b.home_current_balance ),
	SUM( b.net_change_oper )*(1-ABS(SIGN(@s_prev_end_date-b.balance_date))),
 	SUM( b.current_balance_oper )
FROM	#glbal a, glbal b
WHERE	a.balance_date = @s_prev_end_date
AND	a.account_code = b.account_code
AND	b.balance_type = 1
AND b.balance_date <= @s_prev_end_date
AND	b.balance_until >= @s_prev_end_date
GROUP BY
	b.account_code, b.balance_date


UPDATE	#glbal
SET	current_balance = b.current_balance,
	debit = b.debit,
	credit = b.credit,
	net_change = b.net_change,
	current_balance_oper = b.current_balance_oper,
	net_change_oper = b.net_change_oper
FROM	#glbal a, #t1 b
WHERE	a.account_code = b.account_code
AND	a.balance_date = b.balance_date


DELETE	#glbal
WHERE	current_balance = 0.0
AND	balance_date = @s_prev_end_date

RETURN	0
GO
GRANT EXECUTE ON  [dbo].[glcbalsp_sp] TO [public]
GO
