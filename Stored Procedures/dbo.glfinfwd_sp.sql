SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROC [dbo].[glfinfwd_sp]
	@fin_code	varchar(16),
	@current_period	int,
	@year_end	int,
	@year_start	int

AS 
DECLARE @new_amt float,		@old_amt float, 	@diff float, 
	@min_account_code varchar(32),								
	@old_qty float,		@qty float, 		@account varchar(32), 	
	@lastacct char(32), 	@unit varchar(16)

CREATE TABLE #glnftmp
(
	sequence_id		int	NOT NULL,
	nonfin_budget_code	varchar(16)	NOT NULL,
	period_end_date		int		NOT NULL,
	account_code		varchar(32)	NOT NULL,
	unit_of_measure		varchar(16) NOT NULL,
	quantity		float			NOT NULL,
	ytd_quantity		float		NOT NULL,
 seg1_code 		varchar(32) NULL,
 seg2_code 		varchar(32) NULL,
 seg3_code 		varchar(32) NULL,
 seg4_code 		varchar(32) NULL,
	changed_flag		smallint	NOT NULL
)


SELECT @account = '', @lastacct = ''

											
WHILE ( 1 = 1 )
BEGIN
	SET	ROWCOUNT 500

	INSERT #glnftmp (
		sequence_id,	nonfin_budget_code,	period_end_date,	 
		account_code,	unit_of_measure,	quantity,	 
		ytd_quantity,	seg1_code, 	 seg2_code, 	 
	 seg3_code, 	seg4_code, 	 	changed_flag )	 
	SELECT 	sequence_id,	nonfin_budget_code,	period_end_date,	 
		account_code,	unit_of_measure,	quantity,	 
		ytd_quantity,	seg1_code, 	 seg2_code, 	 
	 seg3_code, 	seg4_code, 	 	changed_flag
	FROM	glnofind
	WHERE	nonfin_budget_code = @fin_code
	AND	period_end_date = @current_period
	AND	account_code > @lastacct
	ORDER BY account_code

	IF ( @@ROWCOUNT < 500 )
		BREAK

	SELECT 	@lastacct = MAX( account_code )
	FROM	#glnftmp

END

SET	ROWCOUNT 0
SELECT @account = '', @lastacct = ''


WHILE (1=1)
BEGIN
 	
 	SELECT @lastacct = @account, @account = NULL, @old_amt = 0,
 	@new_amt = 0, @old_qty = 0, @qty = 0

 	
 	SELECT 	@min_account_code = MIN(account_code)				
 	FROM 	#glnofind											
 	WHERE nonfin_budget_code = @fin_code						
 	AND 	period_end_date = @current_period					
	AND	changed_flag = 1										
 	AND	account_code > @lastacct								

 	SELECT 	@account = account_code,
 	 	@qty = quantity,
		@unit = unit_of_measure
 	FROM 	#glnofind
 	WHERE nonfin_budget_code = @fin_code
 	AND 	period_end_date = @current_period
	AND	changed_flag = 1
 	AND	account_code > @lastacct
	AND account_code = @min_account_code						

 	
 	IF ( @account IS NULL )
		BREAK

	
	IF NOT EXISTS ( SELECT	nonfin_budget_code
			FROM	glnofind
		 	WHERE nonfin_budget_code = @fin_code
		 	AND	account_code = @account
		 	AND 	period_end_date = @current_period )
	BEGIN
		
		SELECT	@diff = quantity
	 	FROM 	#glnofind
 		WHERE	account_code = @account
	 	AND	nonfin_budget_code = @fin_code
 		AND	period_end_date = @current_period

		
	 	INSERT 	glnofind ( 
			sequence_id,		nonfin_budget_code,	
			period_end_date,	account_code,
			unit_of_measure,	quantity, 
			ytd_quantity,		seg1_code,
			seg2_code,		seg3_code,
			seg4_code,		changed_flag )
 		SELECT	sequence_id, 		nonfin_budget_code, 
			period_end_date, 	account_code,
			unit_of_measure, 	quantity, 
			ytd_quantity,	 	seg1_code,
			seg2_code,	 	seg3_code,
			seg4_code,		0
	 	FROM 	#glnofind
 		WHERE	account_code = @account
	 	AND	nonfin_budget_code = @fin_code
 		AND	period_end_date = @current_period
	END
	ELSE
	BEGIN
	 	
 		SELECT 	@old_amt = isnull( SUM(quantity), 0 )
 		FROM 	glnofind
	 	WHERE	account_code = @account
 		AND	nonfin_budget_code = @fin_code
	 	AND	period_end_date > @year_start
 		AND	period_end_date < @current_period

		
		SELECT	@new_amt = isnull( @old_amt, 0 ) + @qty

		
		SELECT	@old_qty = isnull( quantity, 0 )
	 	FROM 	glnofind
 		WHERE	account_code = @account
	 	AND	nonfin_budget_code = @fin_code
 		AND	period_end_date = @current_period

		SELECT	@diff = @qty - @old_qty

		
	 	UPDATE 	glnofind
 		SET	quantity = @qty,
			ytd_quantity = @new_amt,
			unit_of_measure = @unit
	 	WHERE	account_code = @account
 		AND	nonfin_budget_code = @fin_code
	 	AND	period_end_date = @current_period

		
		DELETE	#glnofind
		WHERE	account_code = @account
	 	AND	period_end_date = @current_period
	END

 	
 	UPDATE 	glnofind
 	SET	ytd_quantity = ytd_quantity + @diff
 	WHERE	account_code = @account
 	AND	nonfin_budget_code = @fin_code
 	AND	period_end_date > @current_period
 	AND	period_end_date < @year_end

	
	DELETE #glnftmp WHERE account_code = @account
END


SELECT @account = '', @diff = 0


WHILE	(1=1)
BEGIN
	 
 	SELECT @lastacct = @account, @account = NULL

 	
	SELECT 	@account = t2.account_code,
		@diff = t2.quantity
	FROM	#glnftmp t1, #glnftmp t2
	WHERE 	t1.account_code 
	NOT IN ( SELECT account_code FROM #glnofind
		WHERE period_end_date = @current_period )
	AND	t1.period_end_date = @current_period
	AND	t1.account_code = t2.account_code
 	AND	t1.account_code > @lastacct
	ORDER BY t1.account_code DESC

 	
 	IF ( @account IS NULL )
		BREAK

 	
 	UPDATE 	glnofind
 	SET	ytd_quantity = ( ytd_quantity - @diff )
 	WHERE	account_code = @account
 	AND	nonfin_budget_code = @fin_code
 	AND	period_end_date > @current_period
 	AND	period_end_date < @year_end

	
 	DELETE	glnofind
 	WHERE	account_code = @account
 	AND	nonfin_budget_code = @fin_code
 	AND	period_end_date = @current_period
END
GO
GRANT EXECUTE ON  [dbo].[glfinfwd_sp] TO [public]
GO
