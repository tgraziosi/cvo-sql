SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glcbal_sp] (
	@first_time	smallint,
	@spot_adj_flag	smallint,
	@period		int,		
	@p_period	int,		
	@p_prev_period	int,		
	@s_currency	varchar(8),	
	@p_currency	varchar(8)	,
	@s_currency_oper	varchar(8), 
	@p_currency_oper	varchar(8), 
	@rate_type_home		varchar(8),  
	@rate_type_oper		varchar(8) ) 
AS
DECLARE @start_period int, @s_next_period int


DELETE	#glbal

CREATE TABLE #t1 (
 account_code varchar(32)		NOT NULL,
 balance_date int				NOT NULL,		
		debit 					float			NOT NULL,
 		credit					float			NOT NULL,
 current_balance float			NOT NULL,
 net_change float 			NOT NULL,
	current_balance_oper	float		NOT NULL,
	net_change_oper		float		NOT NULL
 )

INSERT	#glbal (
	account_code,	balance_date,		debit,
	credit ,	net_change,		current_balance,	
	account_type,	consol_type,		detail_flag,
	net_change_oper,	current_balance_oper )
SELECT	account_code,	@period, 		0,		
	0,		0,			0,
	account_type,	consol_type,		consol_detail_flag,
	0,	0
FROM	glchart 




SET ROWCOUNT 1
SELECT * INTO #glbalsave FROM #glbal
SET ROWCOUNT 0


IF	@first_time = 1
	SELECT	@start_period = MIN( balance_date )
	FROM	glbal_vw
ELSE
BEGIN
	SELECT	@start_period = MAX( period_end_date )
	FROM	glprd
	WHERE	period_end_date <= @period
	AND	period_type = 1001
END


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
	@period,	
	SUM( home_debit ),
	SUM( home_credit ),
	SUM( home_net_change )*(1-ABS(SIGN(@period-b.balance_date))),
 	SUM( home_current_balance ),
	SUM( b.net_change_oper )*(1-ABS(SIGN(@period-b.balance_date))),
 	SUM( b.current_balance_oper )
FROM	#glbal a, glbal b
WHERE	a.balance_date = @period
AND	a.account_code = b.account_code
AND	b.balance_type = 1
AND b.balance_date <= @period
AND	b.balance_until >= @period
GROUP BY b.account_code, b.balance_date


UPDATE	#glbal
SET	current_balance = b.current_balance,
	debit = b.debit,
	credit = b.credit,
	net_change = b.net_change,
	net_change_oper = b.net_change_oper,
	current_balance_oper = b.current_balance_oper
FROM	#glbal a, #t1 b
WHERE	a.account_code = b.account_code
AND	a.balance_date = b.balance_date


IF	@first_time = 1
	DELETE	#glbal
	WHERE	current_balance = 0.0
	AND	balance_date = @period 
ELSE
	DELETE	#glbal
	WHERE	net_change = 0.0
	AND	balance_date = @period


IF	@first_time = 0 AND @spot_adj_flag = 1 AND EXISTS ( 
	SELECT * FROM glchart 
	WHERE 	consol_type = 3		
	AND	account_type != 350	
	AND	account_type != 600 )	

	
	EXEC glcbalsp_sp @period, @p_period, @p_prev_period, @s_currency,
	 @p_currency, @s_currency_oper, @p_currency_oper, @rate_type_home, @rate_type_oper



IF (SELECT COUNT (*) FROM #glbal) = 0 
BEGIN
 INSERT INTO #glbal SELECT * FROM #glbalsave
 DROP TABLE #glbalsave
 SELECT 1
 RETURN
end 



SELECT 0
RETURN

GO
GRANT EXECUTE ON  [dbo].[glcbal_sp] TO [public]
GO
