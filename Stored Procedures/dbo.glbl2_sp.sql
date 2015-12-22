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










CREATE PROC [dbo].[glbl2_sp] 
	@WhereClause varchar(255)
AS
DECLARE
	@string1		varchar(255),
	@string2		varchar(255),
	@end_date_prime		int,		
	@date_period_end	int,		
	@current_year_end	int,		
	@current_year_start	int,		
	@prior_year_end		int,		
	@prior_year_start	int,		

	@period_end_date	int,
	@period_start_date	int,
	@period_desc		varchar(30),
	@current_period_end_date	int,
	@current_period_start_date	int,
	@current_period_desc		varchar(30),
	@prior_period_end_date	int,
	@prior_period_start_date	int,
	@prior_period_desc		varchar(30),

	@home_company_code	varchar(8),

	@current_net_balance		float,
	@current_net_credit		float,
	@current_net_debit		float,
	@prior_net_balance		float,
	@prior_net_debit		float,
	@prior_net_credit		float,
	@account_code 		varchar(34),
	@post_status		smallint,
	@pos 			smallint,
	@pos1 			smallint,
	@account_id		int,
	@period_id		int,
	@row_return		int




SELECT	@row_return = 0,
	@date_period_end = 0,
	@post_status = 2	




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



SELECT	@current_year_end=MIN(period_end_date)
FROM	glprd
WHERE	period_end_date >= @date_period_end
AND	period_type = 1003

SELECT	@prior_year_end = MAX(period_end_date)
FROM	glprd
WHERE	period_end_date < @current_year_end
AND	period_type = 1003




SELECT	@current_year_start=MAX(period_end_date)
FROM	glprd
WHERE	period_end_date <= @date_period_end
AND	period_type = 1001

SELECT	@prior_year_start = MAX(period_end_date)
FROM	glprd
WHERE	period_end_date < @current_year_start
AND	period_type = 1001




CREATE TABLE #account_codes
(
	account_code            varchar(32) 	NOT NULL,
	account_id		numeric identity
)




CREATE TABLE #periods
(
	current_period_start_date	int,
	current_period_end_date		int,
	current_period_desc		varchar(30),
	prior_period_start_date	int,
	prior_period_end_date		int,
	prior_period_desc		varchar(30),
	period_id			numeric identity
)
CREATE TABLE #current_periods
(
	period_start_date	int,
	period_end_date		int,
	period_desc		varchar(30)
)
CREATE TABLE #prior_periods
(
	period_start_date	int,
	period_end_date		int,
	period_desc		varchar(30)
)



CREATE TABLE #balances
(
	account_code		varchar(32)	NOT NULL,
	post_status		int		NOT NULL,
	date_period_end		int		NOT NULL,
	period_desc		varchar(30)	NOT NULL,
	current_net_debit	float		NOT NULL,
	current_net_credit	float		NOT NULL,
	current_net_balance	float		NOT NULL,
	prior_net_balance	float		NOT NULL
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




insert #current_periods (
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
	period_end_date <= @current_year_end
and	period_end_date >= @current_year_start	
order by 
	period_end_date




insert #prior_periods (
	period_start_date,
	period_end_date,
	period_desc)
	
select
	ISNULL(period_start_date,0),
	ISNULL(period_end_date,0),
	ISNULL(period_description,"")
from
	glprd
where
	period_end_date <= @prior_year_end
and	period_end_date >= @prior_year_start	
order by 
	period_end_date




insert #periods (
	current_period_start_date,
	current_period_end_date,
	current_period_desc,
	prior_period_start_date,
	prior_period_end_date,
	prior_period_desc)
select
	c.period_start_date,
	c.period_end_date,
	c.period_desc,
	p.period_start_date,
	p.period_end_date,
	p.period_desc
from
	#current_periods c, #prior_periods p
where	c.period_desc = p.period_desc





delete #balances



SELECT	@account_code = account_code,
	@account_id = account_id
FROM	#account_codes
WHERE	account_id = (SELECT MIN (account_id) FROM #account_codes)

SELECT @row_return = @@ROWCOUNT
WHILE (@row_return > 0 AND @account_id IS NOT NULL)
BEGIN

	


	SELECT
		@current_net_balance = 0,
		@current_net_credit = 0,
		@current_net_debit =0,
		@prior_net_debit =0,
		@prior_net_credit =0,
		@prior_net_balance =0

	


	SELECT	
		@current_period_start_date = current_period_start_date,
		@current_period_end_date = current_period_end_date,
		@current_period_desc = current_period_desc,
		@prior_period_start_date = prior_period_start_date,
		@prior_period_end_date = prior_period_end_date,
		@period_id = period_id
	FROM	#periods
	WHERE	period_id = (SELECT MIN (period_id) FROM #periods)

	SELECT @row_return = @@ROWCOUNT
	WHILE (@row_return > 0 AND @period_id IS NOT NULL)
	BEGIN

		


		SELECT
			@current_net_debit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @current_period_start_date
					AND @current_period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND (a.posted_flag = @post_status OR @post_status = 2)
			AND a.balance > 0
	
		SELECT
			@current_net_credit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @current_period_start_date
					AND @current_period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND (a.posted_flag = @post_status OR @post_status = 2)
			AND a.balance < 0

		SELECT
			@current_net_balance = @current_net_credit + @current_net_debit

		


		SELECT
			@prior_net_debit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @prior_period_start_date
					AND @prior_period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND (a.posted_flag = @post_status OR @post_status = 2)
			AND a.balance > 0
	
		SELECT
			@prior_net_credit = ISNULL(sum(a.balance),0)
		FROM    gltrx, gltrxdet a 
		WHERE	gltrx.journal_ctrl_num = a.journal_ctrl_num
			AND date_applied BETWEEN @prior_period_start_date
					AND @prior_period_end_date
			AND a.account_code = @account_code
			AND a.rec_company_code = @home_company_code
			AND (a.posted_flag = @post_status OR @post_status = 2)
			AND a.balance < 0

		SELECT
			@prior_net_balance = @prior_net_credit + @prior_net_debit

		


		SELECT
			@current_net_credit = @current_net_credit * (-1)

		


		SELECT  @row_return = count(*)
		FROM	#balances
		WHERE	date_period_end = @current_period_end_date

		IF (@row_return = 0)
		BEGIN
			INSERT INTO #balances (
			account_code,
			post_status,
			date_period_end,
			period_desc,
			current_net_debit,
			current_net_credit,
			current_net_balance,
			prior_net_balance)
			
			SELECT
			@account_code,
			@post_status,
			@current_period_end_date,
			@current_period_desc,
			@current_net_debit,
			@current_net_credit,
			@current_net_balance,
			@prior_net_balance
		END
		ELSE
		BEGIN
			UPDATE #balances
			SET	current_net_debit = current_net_debit + @current_net_debit,
				current_net_credit = current_net_credit + @current_net_credit,
				current_net_balance = current_net_balance + @current_net_balance,
				prior_net_balance = prior_net_balance + @prior_net_balance
			WHERE
				date_period_end = @current_period_end_date
		END
		


		SELECT	
			@current_period_start_date = current_period_start_date,
			@current_period_end_date = current_period_end_date,
			@current_period_desc = current_period_desc,
			@prior_period_start_date = prior_period_start_date,
			@prior_period_end_date = prior_period_end_date,
			@period_id = period_id
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






EXEC (" SELECT * FROM #balances ")


 	  
 
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glbl2_sp] TO [public]
GO
