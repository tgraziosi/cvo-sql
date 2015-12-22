SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glfindet.SPv - e7.2.2 : 1.7
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[glfindet_sp]
 @nonfin_budget_code varchar(16),
 @prev_period	 int,
 @from_period 	int,
 @to_period 	int,
	@year_start		int,
	@year_end		int
AS
DECLARE @numrec int,		@acct_code varchar(32), 
	@qty 	 float, 	@amt 	 float, 
	@tot_qty float,	@seg1_code varchar(32),
	@seg2_code varchar(32),	@seg3_code varchar(32),
	@seg4_code varchar(32)


CREATE TABLE #qty 
( 
	account_code 	varchar(32)	NOT NULL, 
	unit 		varchar(32)	NOT NULL, 
	qty 		float	NOT NULL,
	seg1_code	varchar(32)	NOT NULL,
	seg2_code	varchar(32)	NOT NULL,
	seg3_code	varchar(32)	NOT NULL,
	seg4_code	varchar(32)	NOT NULL
)


INSERT #qty 
	SELECT 	account_code, 
		unit_of_measure, 
		quantity,
		seg1_code,
		seg2_code,
		seg3_code,
		seg4_code
	FROM	glnofind
	WHERE	period_end_date = @from_period
	AND	nonfin_budget_code = @nonfin_budget_code


SELECT 	@acct_code = min(account_code) 
FROM 	#qty 

SELECT 	@numrec = 1


WHILE @acct_code IS NOT NULL
BEGIN
	
	SELECT	@qty = qty
	FROM	#qty
	WHERE	account_code = @acct_code 

	
	SELECT	@amt = isnull( SUM(glnofind.quantity), 0 )
	FROM	glnofind
	WHERE	nonfin_budget_code = @nonfin_budget_code
	AND	account_code = @acct_code
	AND	period_end_date > @year_start
	AND	period_end_date <= @prev_period

	
	SELECT	@tot_qty = @qty + @amt

	INSERT 	glnofind( 
		sequence_id, 	nonfin_budget_code, 	period_end_date, 
		account_code,	unit_of_measure, 	quantity, 
		ytd_quantity,	seg1_code,		seg2_code,
		seg3_code,	seg4_code,		changed_flag )
	SELECT 	@numrec, 	@nonfin_budget_code, 	@to_period, 
		account_code, 	unit, 			qty, 
		@tot_qty,	seg1_code,		seg2_code,
		seg3_code,	seg4_code,		0
	FROM 	#qty 
	WHERE 	account_code = @acct_code

	
	UPDATE 	glnofind 
	SET 	ytd_quantity = ytd_quantity + @qty 
	WHERE 	nonfin_budget_code = @nonfin_budget_code 
	AND 	account_code = @acct_code
	AND 	period_end_date > @to_period 
	AND	period_end_date < @year_end

	
	SELECT @acct_code = ( SELECT min(account_code)
				FROM #qty 
				WHERE account_code > @acct_code )
	SELECT @numrec = @numrec + 1

END 

DROP TABLE #qty


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glfindet_sp] TO [public]
GO
