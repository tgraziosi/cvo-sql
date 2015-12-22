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


































CREATE PROC [dbo].[glbuddet_sp]
        @budget_code    varchar(16),
        @prev_period    int,
        @from_period    int,
        @to_period      int,
	@year_start	int,
	@year_end	int
AS
DECLARE @numrec int, 
	@acct_code 	varchar(32), 
	@bal 		float, 
	@tot_bal 	float, 
        @amt            float,
        @bal_nat        float, 
        @tot_bal_nat    float, 
        @amt_nat        float,
        @bal_oper       float, 
        @tot_bal_oper   float, 
        @amt_oper       float,
	@rate_type      varchar(8),
	@home_currency  varchar(8),
	@oper_currency  varchar(8),
	@rate_home	float,
	@rate_oper	float,
	@nat_cur_code	varchar(8),
	@reference_code	varchar(32)  




CREATE TABLE #tmp 
( 
	account_code 	varchar(32)	NOT NULL, 
	reference_code  varchar(32)	NULL,		
	net 		float		NOT NULL,
	seg1_code	varchar(32)  	NOT NULL,
	seg2_code	varchar(32)	NOT NULL,
	seg3_code	varchar(32)	NOT NULL,
        seg4_code       varchar(32)     NOT NULL,
        nat_net         float           NOT NULL,
        net_oper        float           NOT NULL,
        nat_cur_code    varchar(8),
        



        rate            float,
        rate_oper       float      
)





INSERT #tmp 
	SELECT	account_code, 
		reference_code,	
		net_change,
		seg1_code,
		seg2_code,
		seg3_code,
                seg4_code,
                nat_net_change,
                net_change_oper,
                nat_cur_code,
                



                rate,
                rate_oper      
	FROM 	glbuddet
	WHERE	period_end_date = @from_period
	AND 	budget_code = @budget_code




SELECT @rate_type = rate_type
FROM   glbud
WHERE  budget_code = @budget_code

SELECT @home_currency = home_currency,
       @oper_currency = oper_currency
FROM   glco






DECLARE glbuddet_save CURSOR FOR 
	SELECT	account_code, reference_code, net, nat_net, net_oper, nat_cur_code
	FROM 	#tmp
	ORDER BY account_code, reference_code







SELECT  @numrec = 1





OPEN glbuddet_save


FETCH NEXT FROM glbuddet_save INTO @acct_code, @reference_code, @bal, @bal_nat, @bal_oper, @nat_cur_code

WHILE @@FETCH_STATUS = 0
BEGIN
	


        






	EXEC	CVO_Control..mccurcvt_sp @to_period, 1, @nat_cur_code,
		@bal_nat, @home_currency, @rate_type, @bal OUTPUT,
		@rate_home OUTPUT, 0

	IF (@rate_home IS NULL)
	BEGIN
		
		CLOSE glbuddet_save
		
		DEALLOCATE glbuddet_save
		
		SELECT 0 rate_found
		RETURN 0
	END
	
	EXEC	CVO_Control..mccurcvt_sp @to_period, 1, @nat_cur_code,
		@bal_nat, @oper_currency, @rate_type, @bal_oper OUTPUT,
		@rate_oper OUTPUT, 0

	IF (@rate_oper IS NULL)
	BEGIN
		
		CLOSE glbuddet_save
		
		DEALLOCATE glbuddet_save

		SELECT 0 rate_found
		RETURN 0
	END

	IF (@bal_nat = 0.0)
		SELECT @bal = 0.0, @bal_oper = 0.0

	



        SELECT  @amt = isnull( SUM(glbuddet.net_change), 0 ),
                @amt_nat = isnull( SUM(glbuddet.nat_net_change), 0 ),
                @amt_oper = isnull( SUM(glbuddet.net_change_oper), 0 )
	FROM	glbuddet
	WHERE	budget_code = @budget_code
	AND	account_code = @acct_code
	AND	reference_code = @reference_code
	AND	period_end_date > @year_start
	AND	period_end_date <= @prev_period

	


        SELECT  @tot_bal = @bal + @amt,
                @tot_bal_nat = @bal_nat + @amt_nat,
                @tot_bal_oper = @bal_oper + @amt_oper

	INSERT	glbuddet ( 
		sequence_id,    budget_code,	        account_code,	reference_code,	
	        net_change,	current_balance,        period_end_date,
		seg1_code,	seg2_code,		seg3_code,
                seg4_code,      changed_flag,   	nat_cur_code,
         	rate, 		rate_oper,      	nat_net_change, 
		nat_current_balance, net_change_oper,  	current_balance_oper )
	SELECT	@numrec, 	@budget_code, 		account_code, 	reference_code,	
	       	@bal, 		@tot_bal, 		@to_period,
		seg1_code,	seg2_code,		seg3_code,
                seg4_code,      0 ,   			nat_cur_code,
                @rate_home,  	@rate_oper, 		nat_net, 	
		@tot_bal_nat, 	@bal_oper,		@tot_bal_oper
	FROM 	#tmp 
	WHERE	account_code = @acct_code AND reference_code = @reference_code

	


	UPDATE	glbuddet
        SET     current_balance = current_balance + @bal,
                nat_current_balance = nat_current_balance + @bal_nat,
                current_balance_oper = current_balance_oper + @bal_oper
	WHERE 	budget_code = @budget_code 
	AND 	account_code = @acct_code
	AND	reference_code = @reference_code
   	AND	period_end_date > @to_period 
	AND	period_end_date < @year_end

	


	
	FETCH NEXT FROM glbuddet_save INTO @acct_code, @reference_code, @bal, @bal_nat, @bal_oper, @nat_cur_code
	


	SELECT @numrec = @numrec + 1

END


CLOSE glbuddet_save

DEALLOCATE glbuddet_save

DROP TABLE #tmp

SELECT 1 rate_found
RETURN 1
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glbuddet_sp] TO [public]
GO
