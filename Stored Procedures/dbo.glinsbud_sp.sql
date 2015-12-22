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





























CREATE PROCEDURE [dbo].[glinsbud_sp]  
	@seq_id	   		int,    	@bud_code    	varchar(16),
	@acct_code 		varchar(32),    @nat_net_change float,
	@nat_current_balance 	float, 		@pd_end_date 	int, 
	@seg1_code 		varchar(32),	@seg2_code 	varchar(32),
	@seg3_code 		varchar(32),    @seg4_code 	varchar(32),
	@nat_cur_code 		varchar(8),
	@rate_type		varchar(8),
	@reference_code		varchar(32)
AS
DECLARE @rate			float,
	@net_change		float,
	@current_balance	float,	
	@rate_oper		float,
	@net_change_oper	float,
	@current_balance_oper	float,
	@home_currency_code	varchar(8),
	@oper_currency_code	varchar(8)





SELECT 	@home_currency_code = home_currency,
 	@oper_currency_code = oper_currency
FROM	glco	





EXEC	CVO_Control..mccurcvt_sp @pd_end_date, 1, @nat_cur_code, 
			@nat_net_change, @home_currency_code, 
			@rate_type, @net_change OUTPUT, 
			@rate OUTPUT, 0	
IF ( @rate IS NULL )
BEGIN
	SELECT 0 rate_defined
	RETURN
END

EXEC	CVO_Control..mccurcvt_sp @pd_end_date, 1, @nat_cur_code, 
			@nat_current_balance, @home_currency_code, 
			@rate_type, @current_balance OUTPUT, 
			@rate OUTPUT, 0

EXEC	CVO_Control..mccurcvt_sp @pd_end_date, 1, @nat_cur_code, 
			@nat_net_change, @oper_currency_code, 
			@rate_type, @net_change_oper OUTPUT, 
			@rate_oper OUTPUT, 0	
IF ( @rate_oper IS NULL )
BEGIN
	SELECT 0 rate_defined
	RETURN
END

EXEC	CVO_Control..mccurcvt_sp @pd_end_date, 1, @nat_cur_code, 
			@nat_current_balance, @oper_currency_code, 
			@rate_type, @current_balance_oper OUTPUT, 
			@rate_oper OUTPUT, 0	

IF ( @nat_net_change = 0.0 )
	SELECT @net_change = 0.0, @net_change_oper = 0.0
IF ( @nat_current_balance = 0.0 )
	SELECT @current_balance = 0.0, @current_balance_oper = 0.0

BEGIN
	
	
	INSERT #glbuddetimp (			
		sequence_id		,
	        budget_code     	,
	        account_code    	,
	        reference_code		, 	
	        net_change      	,
	        current_balance 	,
	        period_end_date 	,
	        seg1_code 		,
	        seg2_code 		,
	        seg3_code 		,
	        seg4_code 		,
	        changed_flag		,
		nat_cur_code		,
		rate			,
		rate_oper		,
		nat_net_change	 	,
		nat_current_balance 	,
		net_change_oper		,
		current_balance_oper )
	VALUES (
		@seq_id	   		,
		@bud_code 		,
		@acct_code 		,
		@reference_code		, 	
		@net_change		,
		@current_balance	,
		@pd_end_date		,
	        @seg1_code 		,
	        @seg2_code 		,
	        @seg3_code 		,
	        @seg4_code 		,
	        0			,
		@nat_cur_code		,
		@rate			,
		@rate_oper		,
		@nat_net_change 	,
		@nat_current_balance 	,
		@net_change_oper	,
		@current_balance_oper )

END

SELECT 1 rate_defined
RETURN
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glinsbud_sp] TO [public]
GO
