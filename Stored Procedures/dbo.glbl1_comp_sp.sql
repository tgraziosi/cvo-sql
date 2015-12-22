SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2007 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2007 Epicor Software Corporation, 2007    
                  All Rights Reserved                    
*/                                                












CREATE PROC [dbo].[glbl1_comp_sp] 
	@WhereClause varchar(1024)="" ,
	@comp_name varchar(30)
AS
    DECLARE @SQL VARCHAR(1000)
DECLARE
	@string1		varchar(1000),
	@string2		varchar(1000),
	@first_balance_date	int,
	@last_balance_date	int,
	@include_zero		smallint,
	@current_period_start_date	int,
	@current_period_end_date	int,
	@date_period_start 	int,
	@date_period_end 	int,
	@account_code 		varchar(500),
	@post_status		smallint,
	@pos 			smallint,
	@pos0 			smallint,	
	@pos1 			smallint,
	@account_code_min	varchar(34),
	@account_code_max	varchar(34),
	@org_id_where		varchar(60)





SELECT 	@include_zero = 0		
SELECT	@account_code = ""
SELECT  @account_code_min = ""
SELECT  @account_code_max = ""



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
			AND (charindex('(',@WhereClause) <> 0) 	AND (charindex(')',@WhereClause) <> 0) 
		begin
			


			select @pos1 = charindex(')',@WhereClause)
			select @pos0 = charindex('(',@WhereClause)
			select @account_code = substring(@WhereClause, @pos0+20 ,@pos1- (@pos0+21))
		end	
		else if (charindex('account_code',@WhereClause) <> 0) 
			AND (charindex('(',@WhereClause) <> 0) 	AND (charindex(')',@WhereClause) <> 0) 
		begin
			


			select @pos1 = charindex(')',@WhereClause)
			select @pos0 = charindex('(',@WhereClause)
			select @account_code = substring(@WhereClause, @pos0+14 ,@pos1- (@pos0+14))
		end
		


 		else if (charindex('account_code like',@WhereClause) <> 0)
		begin
			


			select @account_code = substring(@WhereClause, 27 ,@pos1 - 29)
		end
		else if (charindex('account_code BETWEEN',@WhereClause) <> 0)
		begin
			


			select @account_code_min = substring(@WhereClause, 30, @pos1 - 32)
			select @account_code = @account_code_min
			
			select @pos = charindex('AND', substring(@WhereClause, @pos1+3, datalength(@WhereClause)-@pos1-3)) + @pos1 + 3
			if @pos > (@pos1 + 3)
			begin
			


				
				select @account_code_max = substring(@WhereClause, @pos1+5, @pos-(@pos1+8))
			end
		
			else
			begin
			


				select @account_code_max = substring(@WhereClause, @pos1+5, datalength(@WhereClause)-(@pos1+5))
			end
		end
		


		else if (charindex('<',@WhereClause) <> 0) OR (charindex('>',@WhereClause) <> 0)
			OR (charindex('=',@WhereClause) <> 0)
		begin
			select @account_code = substring(@WhereClause, 21,@pos1 - 22)
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
		
		
		select @pos1 = charindex('date_period_end BETWEEN',@WhereClause) + 16
		select @date_period_start = convert(int,substring(@WhereClause, @pos1 + 8,6))
		select @date_period_end   = convert(int,substring(@WhereClause, @pos1 + 19,6))
	end
	else
	begin
		select @pos1 = charindex('date_period_end',@WhereClause)
		select @date_period_end = convert(int,substring(@WhereClause, @pos1 + 16,6))
	end
end

if (charindex('org_id',@WhereClause) <> 0)



begin
	select @pos1 = charindex('org_id',@WhereClause)
	select @org_id_where = ' WHERE ' + substring(@WhereClause, @pos1, len(@WhereClause))
end
else
	select @org_id_where = ""








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
	account_code            varchar(36) 	NOT NULL,
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
	changed_flag            smallint	NOT NULL,
	org_id			varchar(30)	NULL

)

CREATE UNIQUE INDEX balances_ind_0                            
   ON #balances (account_code, account_type, changed_flag)                            









if (@account_code = "")
begin	
	INSERT #balances 
	SELECT DISTINCT 
		account_code, 
	        account_description, 
		account_type,
		0,0,0,0,0,0,0,0,0,
		org_id 
	FROM glchart_w_org_w_sec_vw
end
else
begin
	
	


	if (@account_code_min <> "" AND @account_code_min <> "")
	begin	
		SELECT @string1 = "INSERT #balances SELECT DISTINCT account_code, " +
		          "account_description, account_type,"
		SELECT @string2 = "0,0,0,0,0,0,0,0,0,org_id FROM glchart_w_org_w_sec_vw "
		
        SET @SQL = @string1 + @string2 + " WHERE account_code BETWEEN '" + @account_code_min + "' AND '" + @account_code_max + "'"	
        EXEC (@SQL)		
	end
	


	


	else if (charindex('%',@account_code) = 0)
	begin

	SELECT @string1 = "INSERT #balances " +
			  "SELECT DISTINCT " +
			  "account_code, " +
		          "account_description, " +
			  "account_type, " +
			  "0,0,0,0,0,0,0,0,0, org_id " +
		   	  "FROM glchart_w_org_w_sec_vw " +
			  "WHERE account_code " + @account_code + ""
	EXEC (@string1)
	


	end
	else if (charindex('%',@account_code) = 0)
	begin
	INSERT #balances 
	SELECT DISTINCT 
		account_code, 
	        account_description, 
		account_type,
		0,0,0,0,0,0,0,0,0,org_id 
	FROM glchart_w_org_w_sec_vw
	WHERE account_code = @account_code
	end
	


	else
	begin	
		SELECT @string1 = "INSERT #balances SELECT DISTINCT account_code, " +
		          "account_description, account_type,"
		SELECT @string2 = "0,0,0,0,0,0,0,0,0,org_id FROM glchart_w_org_w_sec_vw "
		EXEC (@string1 + @string2  + " WHERE account_code like '" + @account_code + "'")
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




select @string1 =	"SELECT " +
			"company_name='" + @comp_name + "', " +
			" account_code, " +
			"post_status=" + convert(varchar(4),@post_status) + ", " +
			"org_id, " +
			"date_period_end=" + convert(varchar(11),@date_period_end) + ", " +
			"beginning_balance, " +
			"net_change=ending_balance - beginning_balance, " +
			"ending_balance, " +
			"oper_beginning_balance, " +
			"oper_net_change=oper_ending_balance - oper_beginning_balance, " +
			"oper_ending_balance, " +
	 	  	
			
			"x_date_period_end=" + convert(varchar(11),@date_period_end) + ", " +
			"x_beginning_balance=beginning_balance, " +
			"x_net_change=ending_balance - beginning_balance, " +
			"x_ending_balance=ending_balance, " +
			"x_oper_beginning_balance=oper_beginning_balance, " +
			"x_oper_net_change=oper_ending_balance - oper_beginning_balance, " +
			"x_oper_ending_balance=oper_ending_balance " +
			
			"FROM " +
				"#balances " +
			@org_id_where

EXEC (@string1)

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glbl1_comp_sp] TO [public]
GO
