SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO



CREATE PROCEDURE [dbo].[gltrlbal_sp]
				@start_date	int,
				@end_date	int,
				@non_zero	int,
				@posted		int,
				@curr_flag	smallint,
				@activity_flag	smallint,
				@journal_range_flag	smallint
					

AS
DECLARE
	@prec					int,
	@begin_period_end_date	int
BEGIN

CREATE TABLE #tmp_bal
(
	account_code		varchar(32),
	ending_balance		float,
	oper_ending_balance	float,
	bal_flag			tinyint
)


CREATE INDEX tmp_bal_ind_0                            
   ON #tmp_bal (account_code, bal_flag) 


/*
** after removal of unposted
** posted = 0, both = 1
** so I add 1 to compability
*/
SELECT	@posted = @posted + 1


IF (@activity_flag = 0)
BEGIN
	SELECT	@begin_period_end_date = MAX(period_end_date)
	FROM	glprd
	WHERE	period_end_date <= @end_date AND
			period_type = 1001
END

IF (@posted != 1) /* unposted or both */
BEGIN
	IF (@activity_flag = 0)
	BEGIN
		INSERT	#tmp_bal
		SELECT	b.account_code, 
				SUM(d.balance), 
				SUM(d.balance_oper),
				0
		FROM	#journal_typ t, gltrxdet d, #balances b
		WHERE	b.account_code = d.account_code
		AND	d.posted_flag = 0
		AND	d.journal_ctrl_num = t.journal_ctrl_num
		AND	t.date_applied <= @end_date
		GROUP BY	b.account_code
	END
	ELSE
	BEGIN
		INSERT	#tmp_bal
		SELECT	b.account_code, SUM(d.balance), SUM(d.balance_oper), 0
		FROM	#journal_typ t, gltrxdet d, #balances b
		WHERE	b.account_code = d.account_code
		AND		d.posted_flag = 0
		AND		d.journal_ctrl_num = t.journal_ctrl_num
		AND		t.date_applied <= @end_date
		AND		t.date_applied >= @start_date
		GROUP BY	b.account_code
	END
	
	UPDATE 	#balances
	SET	   	ending_balance = b.ending_balance + t.ending_balance,
			oper_ending_balance = b.oper_ending_balance + t.oper_ending_balance,
			dirty_post = 1
	FROM   	#balances b, #tmp_bal t
	WHERE	t.account_code = b.account_code	
	AND     ( t.ending_balance != 0.0 OR t.oper_ending_balance != 0.0 ) 

END

DELETE #tmp_bal

IF (@posted != 0) /* posted or both */
BEGIN

	/* If NOT exist journal_type in range options,  get the balance from glbal*/

	IF (@journal_range_flag = 0)
	BEGIN
		IF (@activity_flag = 0)
		BEGIN
			INSERT	#tmp_bal
			SELECT	g.account_code,
					SUM(home_current_balance),
					SUM(current_balance_oper),
					0
			FROM	glbal g, #balances b
			WHERE 	g.account_code = b.account_code
			AND		g.balance_date >= @start_date
			AND		g.balance_date <= @end_date
			AND	g.balance_date = (
				SELECT 	MAX(balance_date)
				FROM	glbal
				WHERE	account_code = b.account_code
				AND	balance_date >= @start_date
				AND	balance_date <= @end_date	
					)
			GROUP BY	g.account_code

			UPDATE	#tmp_bal
			SET		bal_flag = 1
			FROM
					glbal r, #tmp_bal t
			WHERE
					r.account_code = t.account_code AND
					(
						r.bal_fwd_flag = 1 OR
						r.balance_date BETWEEN @begin_period_end_date AND @end_date
					)

			UPDATE	#tmp_bal
			SET		ending_balance = 0.0,
					oper_ending_balance = 0.0
			WHERE	bal_flag = 0
		END
		ELSE
		BEGIN
			INSERT	#tmp_bal		
			SELECT	g.account_code,
					SUM(home_net_change),
					SUM(net_change_oper),
					0
			FROM	glbal g, #balances b
			WHERE 	g.account_code = b.account_code
			AND		g.balance_date >= @start_date
			AND		g.balance_date <= @end_date
	/*
			AND	g.balance_date = (
				SELECT 	MIN(balance_date)
				FROM	glbal
				WHERE	account_code = b.account_code
				AND	balance_date >= @start_date
				AND	balance_date <= @end_date	
					)
	*/
			GROUP BY	g.account_code
		END
	END

	ELSE	/* If exist journal_type in range options,  get the balance from gltrx, gltrxdet*/

	BEGIN
		IF (@activity_flag = 0)
		BEGIN
			INSERT	#tmp_bal
			SELECT	b.account_code, 
					SUM(d.balance), 
					SUM(d.balance_oper),
					0
			FROM	#journal_typ t, gltrxdet d, #balances b
			WHERE	b.account_code = d.account_code
			AND	d.journal_ctrl_num = t.journal_ctrl_num
			AND	d.posted_flag = 1			
			AND	t.date_applied <= @end_date
			GROUP BY	b.account_code
		END
		ELSE
		BEGIN
			INSERT	#tmp_bal
			SELECT	b.account_code, SUM(d.balance), SUM(d.balance_oper), 0
			FROM	#journal_typ t, gltrxdet d, #balances b
			WHERE	b.account_code = d.account_code
			AND		d.posted_flag = 1
			AND		d.journal_ctrl_num = t.journal_ctrl_num
			AND		t.date_applied <= @end_date
			AND		t.date_applied >= @start_date
			GROUP BY	b.account_code
		END

	END

	UPDATE 	#balances
	SET	   	ending_balance = b.ending_balance + t.ending_balance,
			oper_ending_balance = b.oper_ending_balance + t.oper_ending_balance
	FROM   	#balances b, #tmp_bal t
	WHERE	t.account_code = b.account_code	


END


DROP TABLE #tmp_bal

IF (@non_zero = 1)
	IF ( @curr_flag = 0 ) /* Home Currency */
	BEGIN
		SELECT	@prec = curr_precision 
		FROM	glcurr_vw, glco
		WHERE	currency_code = home_currency

		DELETE #balances
		WHERE	ROUND(ending_balance,@prec) = 0
	END
	ELSE 	/* Operational currency */
	BEGIN
		SELECT	@prec = curr_precision 
		FROM	glcurr_vw, glco
		WHERE	currency_code = oper_currency

		DELETE #balances
		WHERE	ROUND(oper_ending_balance,@prec) = 0
	END





END		
GO
GRANT EXECUTE ON  [dbo].[gltrlbal_sp] TO [public]
GO
