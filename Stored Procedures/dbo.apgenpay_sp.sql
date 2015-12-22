SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                






































































  



					  

























































 






































































































































































































































































































































































































































































































































































































































































































                       






























































































































CREATE PROCEDURE [dbo].[apgenpay_sp]
	@cash_acct_code varchar(32),    @all_due_date smallint,   @from_due_date int,
	@to_due_date int,               				@limit_check_flag smallint,
	@from_check_amt float,          				@to_check_amt float,
	@limit_amount_flag smallint,    				@max_amt float,
	@force_disc_flag smallint,      				@batch_code varchar(16),        
	@current_date int,              				@date_applied int,              
	@payment_flag smallint,         				@payment_code varchar(8),
	@user_id smallint,								@currency_code varchar(8),
	@rate_type_home varchar(8),			@rate_type_oper varchar(8),
	@process_group_num varchar(16),	@debug_level smallint = 0
AS
	DECLARE @result int,
			@home_cur_code varchar(8),
			@oper_cur_code varchar(8),
			@rate_home float,
			@rate_oper float

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgenpay.cpp" + ", line " + STR( 73, 5 ) + " -- ENTRY: "

SELECT @home_cur_code = home_currency,
	   @oper_cur_code = oper_currency
FROM glco 


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgenpay.cpp" + ", line " + STR( 80, 5 ) + " -- MSG: " + "---Get payment rates"
IF @currency_code = @home_cur_code
   SELECT @rate_home = 1.0
ELSE
   BEGIN	
	SELECT @rate_home = 0.0
	EXEC @result = CVO_Control..mccurate_sp	@date_applied, 
						@currency_code, 
					  	@home_cur_code, 
						@rate_type_home,
						@rate_home OUTPUT,
						0

		 IF ((@result != 0) OR ((ABS((@rate_home)-(0.0)) < 0.0000001)))
			RETURN -7
   END


IF @currency_code = @oper_cur_code
   SELECT @rate_oper = 1.0
ELSE
  BEGIN
    SELECT @rate_oper = 0.0
	EXEC @result = CVO_Control..mccurate_sp	@date_applied, 
						@currency_code, 
						@oper_cur_code, 
						@rate_type_oper,
						@rate_oper OUTPUT,
						0
		 IF ((@result != 0) OR ((ABS((@rate_oper)-(0.0)) < 0.0000001)))
			RETURN -7
   END




CREATE TABLE #apgpvch (trx_ctrl_num varchar(16),
			vendor_code char(12),
			pay_to_code char(8),
			date_applied int,
			date_due int,
			ovpc_flag smallint,
			payment_code varchar(8),
			nat_cur_code varchar(8),
			rate_home float,
			rate_oper float,
			rate_type_home varchar(8),
			rate_type_oper varchar(8),
			amt_to_pay float,
			amt_disc_to_take float,
			org_id varchar(30) NULL)

CREATE CLUSTERED INDEX apgpvch_ind_1 ON #apgpvch (vendor_code, pay_to_code, date_due)



exec @result = apgpvch_sp @all_due_date, 	@from_due_date,
			  @to_due_date,   	@force_disc_flag,
			  @current_date, 	@payment_flag,
			  @payment_code,	@currency_code,
			  @process_group_num,	1,
			  @debug_level,		@cash_acct_code


CREATE TABLE #pay_header  (
       id int,
	   trx_ctrl_num varchar(16),
	   vendor_code varchar(12),
	   pay_to_code varchar(8),
	   payment_code varchar(8),
	   amt_payment float,
	   amt_disc_taken float,
	   printed_flag smallint,
	   hold_flag smallint,
	   org_id varchar(30) NULL
	  )
CREATE CLUSTERED INDEX pay_header_ind_1 ON #pay_header (id)



CREATE TABLE #pay_detail  (
      id int,
	  trx_ctrl_num varchar(16),
	  sequence_id int,
	  apply_to_num varchar(16),
	  amt_applied float,
	  amt_disc_taken float,
	  vo_amt_applied float,
	  vo_amt_disc_taken float,
	  gain_home float,
	  gain_oper float,
	  nat_cur_code varchar(8),
	  vendor_code varchar(12),
	  date_due int,
	  cross_rate float,
	  org_id varchar(30) NULL
	  )
CREATE CLUSTERED INDEX pay_detail_ind_1 ON #pay_detail (id)



EXEC @result = apgppay_sp @date_applied,
			  @currency_code,
			  @rate_type_home,
			  @rate_type_oper,
			  @rate_home,
			  @rate_oper,
			  @debug_level

DROP TABLE #apgpvch


IF (@limit_check_flag = 1) OR (@limit_amount_flag = 1)
   BEGIN
		EXEC @result = apgplimt_sp @limit_check_flag,
								   @from_check_amt,
								   @to_check_amt,
								   @limit_amount_flag,
								   @max_amt,
								   @debug_level
	END

EXEC @result = apgpint_sp @cash_acct_code, 
			  @date_applied,
			  @user_id,
			  @currency_code,
			  @rate_type_home,
			  @rate_type_oper,
			  @rate_home,
			  @rate_oper,
			  @debug_level


DROP TABLE #pay_header
DROP TABLE #pay_detail

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgenpay.cpp" + ", line " + STR( 164, 5 ) + " -- EXIT: "

RETURN  0
GO
GRANT EXECUTE ON  [dbo].[apgenpay_sp] TO [public]
GO
