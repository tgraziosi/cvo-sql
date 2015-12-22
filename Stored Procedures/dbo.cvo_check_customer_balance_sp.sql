SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_check_customer_balance_sp]	@customer_code	varchar(10),
												@aging_days		int,
												@aging_bracket	int												
AS
BEGIN
	DECLARE	@acct_bal	float,
			@age_bal	float

	-- Create working table for CC routine to populate
	CREATE TABLE #past_due_bal (
		amount		float, 
		on_acct		float, 
		age_b1		float, 
		age_b2		float, 
		age_b3		float, 
		age_b4		float, 
		age_b5		float, 
		age_b6		float, 
		home_curr	varchar(8) , 
		age_b0		float)

	-- Call CC routine to get aging
	INSERT #past_due_bal EXEC cc_summary_aging_sp @customer_code, '4', 0, 'CVO', 'CVO'

	IF @aging_bracket = 1  
		SELECT @age_bal = age_b2 FROM #past_due_bal
	ELSE  
	IF @aging_bracket = 2  
		SELECT @age_bal = age_b3 FROM #past_due_bal
	ELSE  
	IF @aging_bracket = 3  
		SELECT @age_bal = age_b4 FROM #past_due_bal
	ELSE  
	IF @aging_bracket = 4  
		SELECT @age_bal = age_b5 FROM #past_due_bal
	ELSE  
	IF @aging_bracket = 5  
		SELECT @age_bal = age_b6 FROM #past_due_bal

	SELECT @acct_bal = amount FROM #past_due_bal

	IF (@acct_bal <= 0 OR @age_bal <= 0)
		RETURN 0
	ELSE
		RETURN 1

END
GO
GRANT EXECUTE ON  [dbo].[cvo_check_customer_balance_sp] TO [public]
GO
