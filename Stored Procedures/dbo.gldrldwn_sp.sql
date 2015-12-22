SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[gldrldwn_sp] (
	@from_account		varchar(32),
	@to_account		varchar(32),
	@from_date		int,
	@to_date		int,
	@debug			smallint = 0)
AS

BEGIN
	


	DECLARE		@period		int, 
			@work_time	datetime

	IF ( @debug > 0 )
	BEGIN
		SELECT	"-----------------------  Entering GLDRLDWN_SP --------------------------"
		SELECT	@work_time = getdate()
	END
	
	CREATE TABLE	#balances (	
					account_code varchar(32)	NOT NULL,
					balance_date_used	int 	NOT NULL,
					current_balance		float	NOT NULL,
					net_change		float 		NOT NULL,
					current_balance_oper		float	NOT NULL,
					net_change_oper		float 		NOT NULL
					)
					
	


	SELECT	period_end_date
	INTO	#periods
	FROM	glprd
	WHERE	period_end_date BETWEEN @from_date AND @to_date

	CREATE INDEX	#periods_ind_0
		ON	#periods ( period_end_date )
	


	SELECT	 distinct account_code
	INTO	#accts
	FROM	glchart_res_by_org_vw  
	WHERE   account_code BETWEEN @from_account AND @to_account

	CREATE INDEX	#accts_ind_0
		ON	#accts ( account_code )
	


	INSERT	#gldrldwn (
		account_code,
		balance_date,
		balance_date_used,
		current_balance,
		net_change,
		account_description,
		account_type,
		inactive_flag,
		current_balance_oper,
		net_change_oper)
	SELECT	distinct a.account_code, 
		p.period_end_date,
		p.period_end_date,
		0.0,
		0.0,
		c.account_description, 
	        c.account_type,
	        c.inactive_flag,
		0.0,
		0.0
	FROM    #periods p, #accts a, glchart c  
	WHERE	a.account_code = c.account_code

	



	SELECT	@period = MIN( period_end_date )
	FROM	#periods

	WHILE ( @period IS NOT NULL )
	BEGIN
		INSERT  #balances(
			account_code,
			balance_date_used,
			current_balance,
			net_change, 
			current_balance_oper,
			net_change_oper )
		SELECT	b.account_code, 
			b.balance_date,
	        	SUM( b.home_current_balance ),
			SUM( b.home_net_change )*(1-ABS(SIGN(@period-b.balance_date))),
	        	SUM( b.current_balance_oper ),
			SUM( b.net_change_oper )*(1-ABS(SIGN(@period-b.balance_date)))
		FROM	glbal b, #accts t
		WHERE  	b.account_code = t.account_code
		AND	b.balance_type = 1
		AND    	b.balance_date <= @period
		AND	b.balance_until >= @period
		GROUP BY
			b.account_code, b.balance_date
		




		UPDATE 	#gldrldwn
		SET	current_balance = b.current_balance,
			net_change = b.net_change,
			balance_date_used = b.balance_date_used,
			current_balance_oper = b.current_balance_oper,
			net_change_oper = b.net_change_oper
		FROM	#gldrldwn g, #balances b
		WHERE	g.account_code = b.account_code
		AND	g.balance_date = @period

		


		DELETE	#periods 
		WHERE	period_end_date = @period
		
		TRUNCATE TABLE	#balances
		


		SELECT	@period = NULL
		SELECT 	@period = MIN( period_end_date )
		FROM	#periods
	END
	



	IF ( @debug > 0 )
	BEGIN
		SELECT	"Execution time: ", datediff(ms, @work_time, getdate() ),"ms"
		SELECT	"Number of entries in #gldrldwn: ",count(*) from #gldrldwn
		SELECT	"--------------------- Leaving GLDRLDWN_SP ------------------------"
	END
	


	DROP TABLE	#accts
	DROP TABLE	#periods
	DROP TABLE	#balances

	RETURN 0
END




GO
GRANT EXECUTE ON  [dbo].[gldrldwn_sp] TO [public]
GO
