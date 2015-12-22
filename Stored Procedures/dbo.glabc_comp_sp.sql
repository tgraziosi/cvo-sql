SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                









CREATE PROC [dbo].[glabc_comp_sp] 
	@WhereClause varchar(1024)='', @comp_name varchar(30)
AS
DECLARE
	@budget_code		varchar(18),
	@string1		varchar(255),
	@string2		varchar(255),
	@first_balance_date	int,
	@last_balance_date	int,
	@include_zero		smallint,
	@current_period_start_date	int,
	@current_period_end_date	int,
	@date_period_start 	int,
	@date_period_end 	int,
	@account_code 		varchar(34),
	@post_status		smallint,
	@pos 			smallint,
	@pos1 			smallint




SELECT 	@include_zero = 0		
SELECT	@account_code = NULL
SELECT  @budget_code = NULL




SELECT	@date_period_start = 0
SELECT 	@date_period_end = 0
SELECT	@current_period_end_date = period_end_date
	FROM	glco
SELECT	@current_period_start_date = period_start_date
	FROM	glprd
	WHERE	period_end_date = @current_period_end_date







if (charindex('account_code',@WhereClause) <> 0)



begin
	if (charindex('AND',@WhereClause) <> 0)
	


	begin
		select @pos1 = charindex('AND',@WhereClause)
		if (charindex('account_code like',@WhereClause) <> 0)
		begin
			select @account_code = substring(@WhereClause, 27 ,@pos1 - 29)
		end
		else
		begin
			select @account_code = substring(@WhereClause, 24,@pos1 - 26)
		end
	end
	else
	


	begin
		if (charindex('account_code like',@WhereClause) <> 0)
		begin
			


			select @account_code = substring(@WhereClause, 27 ,(datalength(@WhereClause) - 27))
		end
		else
		begin
			


			select @account_code = substring(@WhereClause, 24,(datalength(@WhereClause) - 24) )
		end
	end
end 

if (charindex('post_status',@WhereClause) <> 0)



begin
	select @pos1 = charindex('post_status',@WhereClause)
	select @post_status = convert(int,substring(@WhereClause, @pos1 + 12, 1))
end

if (charindex('date_period_end',@WhereClause) <> 0)



begin
	


	if (charindex('date_period_end BETWEEN',@WhereClause) <> 0)
	begin
		select @pos1 = charindex('BETWEEN',@WhereClause)
		select @date_period_start = convert(int,substring(@WhereClause, @pos1 + 8,6))
		select @date_period_end   = convert(int,substring(@WhereClause, @pos1 + 19,6))
	end
	else
	begin
		select @pos1 = charindex('date_period_end',@WhereClause)
		select @date_period_end = convert(int,substring(@WhereClause, @pos1 + 16,6))
	end
end

if (charindex('budget_code',@WhereClause) <> 0)



begin
	if (charindex('budget_code like',@WhereClause) <> 0)
	begin	
		select @pos1 = charindex('budget_code like',@WhereClause)
		select @budget_code = substring (@WhereClause, @pos1 + 18,datalength(@WhereClause) - (@pos1 + 18))
	end
	else
	begin
		select @pos1 = charindex('budget_code',@WhereClause)
		select @budget_code = substring(@WhereClause, @pos1 + 15, (datalength(@WhereClause) - (@pos1 + 15)))
	end
end









if (@date_period_end <> 0)
begin
	SELECT	
		@date_period_end = min(period_end_date)
	FROM
		glprd
	WHERE
		period_end_date >= @date_period_end
end
else
begin
	SELECT	@date_period_end = @current_period_end_date
end

if (@date_period_start <> 0)
begin
	SELECT	
		@date_period_start = max(period_start_date)
	FROM
		glprd
	WHERE
		period_start_date <= @date_period_start
end
else
begin
	SELECT	@date_period_start = period_start_date
	FROM	glprd
	WHERE	period_end_date = @date_period_end
end







CREATE TABLE #balances
(
	account_code            varchar(32) 	NOT NULL,
	account_description     varchar(40)	NOT NULL,
	account_type            smallint 	NOT NULL,
	beginning_balance       float		NOT NULL,
	ending_balance          float		NOT NULL,
	prior_fiscal_balance    float		NOT NULL,
	oper_beginning_balance      float	NOT NULL,
	oper_ending_balance         float	NOT NULL,
	oper_prior_fiscal_balance   float  	NOT NULL,
	trx_flag                smallint	NOT NULL,
	dirty_post              smallint	NOT NULL,
	changed_flag            smallint	NOT NULL

)

CREATE UNIQUE INDEX balances_ind_0                            
   ON #balances (account_code, account_type, changed_flag)                            




CREATE TABLE #budgets
(
	budget_code		varchar(16)	NOT NULL,
	account_code    	varchar(32) 	NOT NULL,
	net_change	          float		NOT NULL
	
)










if (@account_code = NULL)
begin	
	INSERT #balances 
	SELECT DISTINCT 
		account_code, 
	        account_description, 
		account_type,
		0,0,0,0,0,0,0,0,0 
	FROM glchart
end
else
begin
	


	if (charindex('%',@account_code) = 0)
	begin
	INSERT #balances 
	SELECT DISTINCT 
		account_code, 
	        account_description, 
		account_type,
		0,0,0,0,0,0,0,0,0 
	FROM glchart
	WHERE account_code = @account_code
	end
	
	


	else
	begin	
		INSERT #balances 
		SELECT DISTINCT 
			account_code, 
	        	account_description, 
			account_type,
			0,0,0,0,0,0,0,0,0 
		FROM glchart
		WHERE account_code like @account_code
	end

end






SELECT 	@first_balance_date=min(period_end_date), 
	@last_balance_date=max(period_end_date)
FROM 	glprd
WHERE 	period_end_date <= @date_period_end
AND 	period_start_date >= @date_period_start







EXEC glbalprd_sp 
	@date_period_start, 
	@first_balance_date,
	@date_period_end, 
	@last_balance_date, 
	@include_zero, 
	@post_status





IF (@budget_code = NULL)



BEGIN
	INSERT #budgets (
		budget_code,
		account_code,
		net_change)
	SELECT
		budget_code,
		account_code,
		sum(net_change)
	FROM	glbuddet
	WHERE	
		period_end_date BETWEEN @date_period_start
				AND	@date_period_end
	GROUP BY
		budget_code, account_code

	SELECT
	company_name = @comp_name,
	a.account_code,
	b.budget_code,
	post_status=@post_status,
	date_period_end=@date_period_end,
	actual_net_change=(a.ending_balance - a.beginning_balance),
	budget_net_change=b.net_change,
	variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	actual_ending_balance=a.ending_balance,
	budget_ending_balance=c.current_balance,
	variance_ending_balance=a.ending_balance - c.current_balance,
	var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END,

	x_date_period_end=@date_period_end,
	x_actual_net_change=(a.ending_balance - a.beginning_balance),
	x_budget_net_change=b.net_change,
	x_variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	x_var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	x_actual_ending_balance=a.ending_balance,
	x_budget_ending_balance=c.current_balance,
	x_variance_ending_balance=a.ending_balance - c.current_balance,
	x_var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END


FROM
	#balances a, #budgets b, glbuddet c
WHERE	
	b.budget_code = c.budget_code
AND	a.account_code = b.account_code
AND	a.account_code = c.account_code
AND	c.period_end_date = @date_period_end



END 
ELSE 



BEGIN
IF (charindex('%',@budget_code) = 0)



BEGIN
	INSERT #budgets (
		budget_code,
		account_code,
		net_change)
	SELECT
		budget_code,
		account_code,
		sum(net_change)
	FROM	glbuddet
	WHERE	budget_code = @budget_code
	AND	period_end_date BETWEEN @date_period_start
				AND	@date_period_end
	GROUP BY
		budget_code, account_code
		
	SELECT
	company_name = @comp_name,
	a.account_code,
	b.budget_code,
	post_status=@post_status,
	date_period_end=@date_period_end,
	actual_net_change=(a.ending_balance - a.beginning_balance),
	budget_net_change=b.net_change,
	variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	actual_ending_balance=a.ending_balance,
	budget_ending_balance=c.current_balance,
	variance_ending_balance=a.ending_balance - c.current_balance,
	var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END,

	x_date_period_end=@date_period_end,
	x_actual_net_change=(a.ending_balance - a.beginning_balance),
	x_budget_net_change=b.net_change,
	x_variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	x_var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	x_actual_ending_balance=a.ending_balance,
	x_budget_ending_balance=c.current_balance,
	x_variance_ending_balance=a.ending_balance - c.current_balance,
	x_var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END

	FROM
		#balances a, #budgets b, glbuddet c
	WHERE	
		b.budget_code = c.budget_code
	AND	a.account_code = b.account_code
	AND	a.account_code = c.account_code
	AND	c.period_end_date = @date_period_end

END 
ELSE



BEGIN
	INSERT #budgets (
		budget_code,
		account_code,
		net_change)
	SELECT
		budget_code,
		account_code,
		sum(net_change)
	FROM	glbuddet
	WHERE	budget_code like @budget_code
	AND	period_end_date BETWEEN @date_period_start
				AND	@date_period_end
	GROUP BY
		budget_code, account_code

	SELECT
	company_name = @comp_name,
	a.account_code,
	b.budget_code,
	post_status=@post_status,
	date_period_end=@date_period_end,
	actual_net_change=(a.ending_balance - a.beginning_balance),
	budget_net_change=b.net_change,
	variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	actual_ending_balance=a.ending_balance,
	budget_ending_balance=c.current_balance,
	variance_ending_balance=a.ending_balance - c.current_balance,
	var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END,

	x_date_period_end=@date_period_end,
	x_actual_net_change=(a.ending_balance - a.beginning_balance),
	x_budget_net_change=b.net_change,
	x_variance_net_change=(a.ending_balance - a.beginning_balance) - b.net_change,
	x_var_perc_net_change=CASE (a.ending_balance - a.beginning_balance) - b.net_change
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN (a.ending_balance - a.beginning_balance) THEN 100
		ELSE
		SIGN((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)*
		((((a.ending_balance - a.beginning_balance) - b.net_change)/b.net_change)*100)
	END,
	x_actual_ending_balance=a.ending_balance,
	x_budget_ending_balance=c.current_balance,
	x_variance_ending_balance=a.ending_balance - c.current_balance,
	x_var_perc_ending_balance=CASE a.ending_balance - c.current_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN a.ending_balance THEN 100
		ELSE
		SIGN(((a.ending_balance - c.current_balance)/c.current_balance)*100)*
		(((a.ending_balance - c.current_balance)/c.current_balance)*100)
	END


	FROM
		#balances a, #budgets b, glbuddet c
	WHERE	
		b.budget_code = c.budget_code
	AND	a.account_code = b.account_code
	AND	a.account_code = c.account_code
	AND	c.period_end_date = @date_period_end


END 

END 




 	  
 
                                              


GO
GRANT EXECUTE ON  [dbo].[glabc_comp_sp] TO [public]
GO
