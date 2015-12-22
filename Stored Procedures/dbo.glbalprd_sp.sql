SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROC [dbo].[glbalprd_sp] @start_date int, 
				@first_balance_date int, 
				@end_date int, 
				@last_balance_date int, 
				@non_zero int, 
				@posted int 
AS

DECLARE @year_start int,
		@year_start_save int



IF (@posted > 0)



BEGIN
	SELECT @year_start = MAX(period_start_date)
	FROM glprd
	WHERE period_type = 1001
	AND (period_start_date <= @first_balance_date)

	CREATE TABLE #glbal_tmp (
		account_code varchar(32)	NOT NULL,
		home_current_balance float		NOT NULL,
		home_net_change float		NOT NULL,
		balance_date int			NOT NULL,
 current_balance_oper float		NOT NULL, 
 net_change_oper float		NOT NULL)

	
	INSERT #glbal_tmp (
		account_code,
		balance_date,
		home_current_balance,
		home_net_change,
 current_balance_oper,
 net_change_oper )

	SELECT b.account_code,
		@first_balance_date,
		SUM( b.home_current_balance ),
		SUM( b.home_net_change )* 
		(1-ABS(SIGN(@first_balance_date-b.balance_date))),
 SUM( b.current_balance_oper ),
 SUM( b.net_change_oper )*
 (1-ABS(SIGN(@first_balance_date-b.balance_date)))
	FROM glbal b, #balances c
	WHERE b.balance_type = 1
	AND b.account_code = c.account_code
	AND b.balance_date <= @first_balance_date
	AND b.balance_until >= @first_balance_date
	GROUP BY b.account_code, b.balance_date


	UPDATE #balances
	SET beginning_balance = t.home_current_balance - 
					t.home_net_change,
		ending_balance = t.home_current_balance,
		oper_beginning_balance = t.current_balance_oper -
 t.net_change_oper,
 oper_ending_balance = t.current_balance_oper

	FROM #glbal_tmp t, #balances b
	WHERE t.account_code = b.account_code

	
	IF @last_balance_date != @first_balance_date
	BEGIN
		SELECT @year_start_save = @year_start

		SELECT @year_start = MAX(period_start_date)
		FROM glprd
		WHERE period_type = 1001
		AND (period_start_date <= @last_balance_date)

		IF ( @year_start_save != @year_start )
		BEGIN 
			
			UPDATE #balances
			SET ending_balance = ending_balance * ((sign(400-account_type)+1)/2),
	 			oper_ending_balance = oper_ending_balance * ((sign(400-account_type)+1)/2)

		END

		DELETE #glbal_tmp

		INSERT #glbal_tmp (
			account_code,
			balance_date,
			home_current_balance,
			home_net_change,
			current_balance_oper, 
 net_change_oper )
		SELECT b.account_code,
			@last_balance_date,
			SUM( b.home_current_balance ),
			SUM( b.home_net_change ) * 
				(1-ABS(SIGN(@last_balance_date-b.balance_date))),
			SUM( b.current_balance_oper ),
 SUM( b.net_change_oper ) *
 (1-ABS(SIGN(@last_balance_date-b.balance_date)))
		FROM glbal b, #balances c
		WHERE b.balance_type = 1
		AND b.account_code = c.account_code
		AND b.balance_date <= @last_balance_date
		AND b.balance_until >= @last_balance_date
		GROUP BY b.account_code, b.balance_date

		
		DECLARE @rounding float, @rounding1 float
		SELECT @rounding = rounding_factor
		FROM CVO_Control..mccurr, glco
		WHERE home_currency = currency_code

		SELECT @rounding1 = rounding_factor
		FROM CVO_Control..mccurr, glco
 WHERE oper_currency = currency_code

		UPDATE #balances 
		SET ending_balance = #glbal_tmp.home_current_balance
		FROM #glbal_tmp, #balances 
		WHERE #glbal_tmp.account_code = #balances.account_code 
		AND (ABS(#glbal_tmp.home_current_balance - #balances.ending_balance) > @rounding)

		SELECT @rounding1 = rounding_factor
		FROM CVO_Control..mccurr, glco
 WHERE oper_currency = currency_code
		
		UPDATE #balances
 SET oper_ending_balance = #glbal_tmp.current_balance_oper
		FROM #glbal_tmp, #balances
		WHERE #glbal_tmp.account_code = #balances.account_code
 AND (ABS(#glbal_tmp.current_balance_oper - #balances.oper_ending_balance) > @rounding1)

	END
	DROP TABLE #glbal_tmp
END



IF ( @posted >= 1 )
BEGIN
	
	CREATE TABLE #ptrx ( account_code varchar(32))

	INSERT #ptrx
	(account_code)
	SELECT DISTINCT account_code
	FROM gltrx h, gltrxdet d
	WHERE h.journal_ctrl_num = d.journal_ctrl_num
	AND date_applied BETWEEN @start_date AND @end_date
	AND h.posted_flag = 1

	
	
	UPDATE #balances 
	SET trx_flag = 1
	FROM #balances b, #ptrx t
	WHERE b.account_code = t.account_code

	DROP TABLE #ptrx
END


IF ( @posted != 1 )
BEGIN
CREATE TABLE #utrxbal
(
account_code	varchar(32),
ubal	float,
ubal1	float
)
CREATE TABLE #utrxbal1
(
account_code	varchar(32),
ubal	float,
ubal1	float
)
CREATE TABLE #utrxbal2
(
account_code	varchar(32),
ubal	float,
ubal1	float
)
	
	SELECT @year_start = MAX(period_start_date) 
	FROM glprd
	WHERE period_start_date <= @first_balance_date
	AND period_type = 1001

	
	INSERT #utrxbal1 (
	account_code,
	ubal,
	ubal1 )
	SELECT a.account_code, 
			sum( balance * ( ( (sign(400-account_type)+1)/2 + (sign(date_applied+1-@year_start)+1)/2 + 1) /2) ),
			sum( balance_oper *
 ( ( (sign(400-account_type)+1)/2 +
 (sign(date_applied+1-@year_start)+1)/2 + 1) /2) ) 
	FROM gltrx h, gltrxdet d, glchart a
	WHERE h.journal_ctrl_num = d.journal_ctrl_num
	AND d.account_code = a.account_code
	AND h.date_applied < @start_date
	AND h.posted_flag = 0
	GROUP BY a.account_code

	
	UPDATE #balances 
	SET beginning_balance = beginning_balance + ubal,
	 	oper_beginning_balance = oper_beginning_balance + ubal1,
		trx_flag = 1,
		dirty_post = 2
	FROM #balances b, #utrxbal1 t
	WHERE b.account_code = t.account_code

	
	SELECT @year_start = MAX(period_start_date) 
	FROM glprd
	WHERE period_start_date <= @last_balance_date
	AND period_type = 1001

	
	INSERT #utrxbal
	(account_code,
	ubal, ubal1)
	SELECT a.account_code, 
			sum( balance * ( ( (sign(400-account_type)+1)/2 + (sign(date_applied+1-@year_start)+1)/2 + 1) /2) ) ,
			 sum( balance_oper * ( ( (sign(400-account_type)+1)/2
 + (sign(date_applied+1-@year_start)+1)/2 + 1) /2) )
	FROM gltrx h, gltrxdet d, glchart a
	WHERE h.journal_ctrl_num = d.journal_ctrl_num
	AND d.account_code = a.account_code
	AND h.date_applied <= @end_date
	AND h.posted_flag = 0
	GROUP BY a.account_code


	
	UPDATE #balances 
	SET ending_balance = ending_balance + ubal,
	 	oper_ending_balance = oper_ending_balance + ubal1,
		trx_flag = 1,
		dirty_post = 1
	FROM #balances b, #utrxbal t
	WHERE b.account_code = t.account_code

	
	INSERT #utrxbal2
	(
	account_code,
	ubal,
	ubal1)
	SELECT a.account_code, 
			sum( balance * ( sign(account_type-399)+1)/2 ) ubal,
			sum( balance_oper * ( sign(account_type-399)+1)/2 ) ubal1
	FROM gltrx h, gltrxdet d, glchart a
	WHERE h.journal_ctrl_num = d.journal_ctrl_num
	AND d.account_code = a.account_code
	AND h.date_applied < @year_start
	AND h.posted_flag = 0
	GROUP BY a.account_code

	
	UPDATE #balances 
	SET prior_fiscal_balance = prior_fiscal_balance + ubal,
	 	oper_prior_fiscal_balance = oper_prior_fiscal_balance + ubal1
	FROM #balances b, #utrxbal2 t
	WHERE b.account_code = t.account_code

	DROP TABLE #utrxbal1
	DROP TABLE #utrxbal2
	DROP TABLE #utrxbal
END

GO
GRANT EXECUTE ON  [dbo].[glbalprd_sp] TO [public]
GO
