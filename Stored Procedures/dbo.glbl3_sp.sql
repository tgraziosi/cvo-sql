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











CREATE PROC [dbo].[glbl3_sp] 
	@WhereClause varchar(255)
AS
DECLARE
	@string1		varchar(255),
	@string2		varchar(255),
	@end_date_prime		int,		
	@year_end		int,		
	@year_start		int,		

	@period_end_date	int,
	@date_period_end	int,
	@period_start_date	int,
	@period_desc		varchar(30),

	@home_company_code	varchar(8),

	@actual_net_balance		float,
	@budget_net_balance		float,
	@variance			float,
	@variance_percent		float,
	@net_credit		float,
	@net_debit		float,

	@account_code 		varchar(34),
	@budget_code		varchar(18),
	@post_status		smallint,
	@pos 			smallint,
	@pos1 			smallint,
	@account_id		int,
	@period_id		int,
	@row_return		int




SELECT	
	@account_code = NULL,
	@budget_code = NULL,
	@row_return = 0,
	@variance = 0,
	@actual_net_balance = 0,
	@budget_net_balance = 0,
	@net_credit = 0,
	@net_debit =0,
	@date_period_end=0




SELECT	@home_company_code = company_code
FROM	glco







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









SELECT	@end_date_prime=glprd.period_end_date
FROM	glco, glprd
WHERE	glprd.period_end_date = glco.period_end_date




IF (@date_period_end <> 0)
BEGIN
	SELECT
		@date_period_end = MIN(period_end_date)
	FROM
		glprd
	WHERE
		period_end_date >= @date_period_end
END




ELSE 
BEGIN
	SELECT	@date_period_end = @end_date_prime
END	




SELECT	@year_end=MIN(period_end_date)
FROM	glprd
WHERE	period_end_date >= @date_period_end
AND	period_type = 1003





SELECT	@year_start=MAX(period_end_date)
FROM	glprd
WHERE	period_end_date <= @date_period_end
AND	period_type = 1001





CREATE TABLE #account_codes
(
	account_code            varchar(32) 	NOT NULL,
	account_id		numeric identity
)




CREATE TABLE #periods
(
	period_start_date	int,
	period_end_date		int,
	period_desc		varchar(30),
	period_id			numeric identity
)



CREATE TABLE #balances
(
	account_code            varchar(32) 	NOT NULL,
	budget_code		varchar(16)	NOT NULL,
	post_status		int		NOT NULL,
	date_period_end		int		NOT NULL,
	period_desc		varchar(30)	NOT NULL,
	actual_net_balance	float		NOT NULL,
	budget_net_balance	float		NOT NULL,
	variance		float		NOT NULL,
	variance_percent	float		NOT NULL
)

CREATE TABLE #temp_balances
(
	account_code            varchar(32) 	NOT NULL,
	budget_code		varchar(16)	NOT NULL,
	date_period_end		int		NOT NULL,
	actual_net_balance	float		NOT NULL,
	budget_net_balance	float		NOT NULL
)




if (@account_code = NULL)
begin	
	EXEC ("insert #account_codes (account_code) select distinct account_code from   glchart")
end
else
begin
	if (charindex('%',@account_code) = 0)
	begin
		insert #account_codes (account_code) 
		select @account_code
	end
	else
	begin	
		EXEC ("insert #account_codes (account_code) select distinct account_code from   glchart where  account_code like '" + @account_code + "'")
	end
end




insert #periods (
	period_start_date,
	period_end_date,
	period_desc)
	
select
	period_start_date,
	period_end_date,
	period_description
from
	glprd
where
	period_end_date <= @year_end
and	period_end_date >= @year_start	
order by 
	period_end_date






DELETE #balances




SELECT	@account_code = account_code,
	@account_id = account_id
FROM	#account_codes
WHERE	account_id = (SELECT MIN (account_id) FROM #account_codes)

SELECT @row_return = @@ROWCOUNT
WHILE (@row_return > 0 AND @account_id IS NOT NULL)
BEGIN


	


	SELECT	
		@period_start_date = period_start_date,
		@period_end_date = period_end_date,
		@period_desc = period_desc,
		@period_id = period_id
	FROM	#periods
	WHERE	period_id = (SELECT MIN (period_id) FROM #periods)

	SELECT @row_return = @@ROWCOUNT
	WHILE (@row_return > 0 AND @period_id IS NOT NULL)
	BEGIN

		


		SELECT
			@net_debit = 0,
			@net_credit = 0,
			@actual_net_balance = 0,
			@budget_net_balance = 0,
			@variance = 0,
			@variance_percent = 0

		


		SELECT
			@net_debit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @period_start_date
					AND @period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND a.posted_flag = @post_status
			AND a.balance > 0
	
		SELECT
			@net_credit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @period_start_date
					AND @period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND a.posted_flag = @post_status
			AND a.balance < 0

		SELECT
			@actual_net_balance = @net_credit + @net_debit

		



		


		IF (@budget_code = NULL)
		BEGIN
			INSERT INTO #balances (
				account_code,
				budget_code,
				post_status,
				date_period_end,
				period_desc,
				actual_net_balance,
				budget_net_balance,
				variance,
				variance_percent)
			
			SELECT
				@account_code,
				ISNULL(b.budget_code,""),
				@post_status,
				@period_end_date,
				@period_desc,
				@actual_net_balance,
				ISNULL(b.net_change,0),
				0,
				0
			FROM	
				#account_codes a 
					LEFT OUTER JOIN glbuddet b ON (a.account_code = b.account_code AND b.period_end_date = @period_end_date)		
			WHERE	
				a.account_code = @account_code			

		END 
		


		ELSE 
		BEGIN
			


			IF (charindex('%',@budget_code) = 0)
			BEGIN
			INSERT INTO #balances (
				account_code,
				budget_code,
				post_status,
				date_period_end,
				period_desc,
				actual_net_balance,
				budget_net_balance,
				variance,
				variance_percent)
			
			SELECT
				@account_code,
				@budget_code,
				@post_status,
				@period_end_date,
				@period_desc,
				@actual_net_balance,
				ISNULL(b.net_change,0),
				0,
				0
			FROM	
				#account_codes a LEFT OUTER JOIN glbuddet b 
					ON (a.account_code = b.account_code		
					AND budget_code = @budget_code
					AND period_end_date = @period_end_date)
			WHERE
				a.account_code 	= @account_code
			END 

			


			ELSE
			BEGIN
			INSERT INTO #balances (
				account_code,
				budget_code,
				post_status,
				date_period_end,
				period_desc,
				actual_net_balance,
				budget_net_balance,
				variance,
				variance_percent)
			
			SELECT
				@account_code,
				ISNULL(b.budget_code,""),
				@post_status,
				@period_end_date,
				@period_desc,
				@actual_net_balance,
				ISNULL(b.net_change,0),
				0,
				0
			FROM
				#account_codes a LEFT OUTER JOIN glbuddet b 
					ON (a.account_code = b.account_code		
					AND budget_code like @budget_code
					AND period_end_date = @period_end_date)
			WHERE
				a.account_code = @account_code
			END 

		END 
		


		SELECT
			@period_start_date 	= period_start_date,
			@period_end_date 	= period_end_date,
			@period_desc 		= period_desc,
			@period_id 		= period_id
		FROM	#periods
		WHERE	period_id = (SELECT MIN(period_id) 
				  FROM #periods
				  WHERE period_id > @period_id)	
		SELECT @row_return = @@ROWCOUNT

	END 






SELECT	@account_code = account_code,
	@account_id = account_id
FROM	#account_codes
WHERE	account_id = (SELECT MIN(account_id) 
		  FROM #account_codes 
		  WHERE account_id > @account_id)	
SELECT @row_return = @@ROWCOUNT

END 






INSERT	#temp_balances (
	account_code,
	budget_code,
	date_period_end,
	actual_net_balance,
	budget_net_balance)

SELECT 
	min(account_code),
	budget_code,
	date_period_end,
	sum(actual_net_balance),
	sum(budget_net_balance)
FROM #balances
GROUP BY budget_code,date_period_end


SELECT  
	b.account_code,
	a.budget_code,
	a.post_status,
	a.date_period_end,
	a.period_desc,
	b.actual_net_balance,
	b.budget_net_balance,
	variance=b.actual_net_balance - b.budget_net_balance,
	variance_percent=
		CASE b.actual_net_balance - b.budget_net_balance
		WHEN NULL THEN 0
		WHEN 0 THEN 0
		WHEN b.actual_net_balance THEN 100
		ELSE
		SIGN(((b.actual_net_balance - b.budget_net_balance)/b.budget_net_balance)*100)*
		(((b.actual_net_balance - b.budget_net_balance)/b.budget_net_balance)*100)
		END
FROM
	#balances a, #temp_balances b
WHERE
	a.budget_code = b.budget_code
AND	a.date_period_end = b.date_period_end
AND	a.account_code = b.account_code
 




 	  
 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glbl3_sp] TO [public]
GO
