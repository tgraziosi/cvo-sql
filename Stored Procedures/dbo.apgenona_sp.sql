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









































































  



					  

























































 






































































































































































































































































































































































































































































































































































































































































































                       





























































































































CREATE PROCEDURE [dbo].[apgenona_sp]
	@cash_acct_code varchar(32),    
	@all_due_date smallint,
	@from_due_date int,
	@to_due_date int,               
	@force_disc_flag smallint,      
	@batch_code     varchar(16),    
	@current_date int,              
	@date_applied int, 
	@user_id smallint,
	@currency_code varchar(8),
	@any_currency smallint,
	@process_group_num varchar(16),
	@debug_level smallint = 0,
	@from_org_onacc varchar(30),   
	@end_org_onacc varchar(30)	
AS
DECLARE 
	@vendor_code    varchar(12),    	  @aprv_check_flag smallint,      
	@pyt_num        varchar(16),    @seq_id         int,            
	@approval_code  varchar(8),     	  @payment_type   smallint,              
	@payment_code   varchar(8),     	  @printed_flag   smallint,       
	@pay_to_code    varchar(8),     	  @doc_ctrl_num   varchar(16),    
	@doc_date       int,            				  @amt_applied    float,          
	@avail_disc     float,          				  @amt_voucher    float,          
	@gen_id         int,            				  @result         smallint,
	@company_code   char(8),              @count int,
	@select_vouch smallint,							  @vo_vendor_code varchar(12),
	@select_onacct smallint,						  @on_vendor_code varchar(12),
	@amt_on_acct   float,							  @vouch_num varchar(16),
	@amt_disc_taken float,							  @hold_flag smallint,
	@vo_pay_to_code varchar(8), 		  @on_pay_to_code varchar(8),
	@date_due int,									  @nat_cur_code varchar(8),			  
	@apply_to_num varchar(16),	  @vo_amt_applied float,							  
	@vo_amt_disc_taken float,						  @rate_type_home varchar(8),
	@rate_type_oper varchar(8),			  @gain_home float,
	@gain_oper float,								  @rate_home float,
	@rate_oper float,								  @home_precision smallint,
	@oper_precision smallint,						  @org_id varchar(30) ,  
	@org_id_vo varchar(30) 	




IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgenona.cpp" + ", line " + STR( 101, 5 ) + " -- ENTRY: "

	
SELECT @company_code = a.company_code, 
	   @home_precision = b.curr_precision,
	   @oper_precision =  c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code





SELECT  @aprv_check_flag = aprv_check_flag,
	@approval_code = default_aprv_code
FROM    apco






IF @aprv_check_flag = 0
	SELECT @approval_code = " "







BEGIN TRAN

UPDATE  apnumber
SET     next_gen_id = next_gen_id + 1

SELECT  @gen_id = next_gen_id
FROM    apnumber


COMMIT TRAN



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



EXEC @result = apgpvch_sp @all_due_date, 	@from_due_date,
			  @to_due_date,   	@force_disc_flag,
			  @current_date, 	0,
			  @payment_code,	@currency_code,
			  @process_group_num,	0,
			  @debug_level, 	@cash_acct_code

IF 	@result != 0
   RETURN @result 


CREATE TABLE #apgooa (trx_ctrl_num varchar(16),
					 vendor_code varchar(12),
					 pay_to_code varchar(8),
					 doc_ctrl_num varchar(16),
					 cash_acct_code varchar(32),
					 date_doc int,
					 nat_cur_code varchar(8),
					 date_applied int,
					 rate_type_home varchar(8),
					 rate_type_oper varchar(8),
					 amt_on_acct float,
					 rate_home float,
					 rate_oper float,
					 payment_code varchar(8),
					 payment_type smallint,
					 org_id varchar(30) NULL
					 )
CREATE CLUSTERED INDEX apgooa_ind_1 ON #apgooa (vendor_code, pay_to_code, date_doc)


EXEC @result = apgooa_sp	@currency_code,
							@any_currency,
							@process_group_num,
							@debug_level,
							@from_org_onacc,		
							@end_org_onacc			

IF 	@result != 0
   RETURN @result 


CREATE TABLE #pay_detail
    (
	 vendor_code varchar(12),
	 pay_to_code varchar(8),
	 apply_to_num varchar(16),
	 amt_applied float,		
	 amt_disc_taken float,
	 cash_acct_code varchar(32),
	 doc_ctrl_num varchar(16),
	 vo_amt_applied float,
	 vo_amt_disc_taken float,
	 gain_home float,
	 gain_oper float,
	 nat_cur_code varchar(8),
	 inserted int,
	 org_id varchar (30) NULL		 
	 	)


EXEC @result = apgoaply_sp  @debug_level
IF @result <> 0
   RETURN @result



DROP TABLE #apgpvch



CREATE TABLE #pay_header
    (
		vendor_code varchar(12),
		pay_to_code varchar(8),		
		doc_ctrl_num varchar(16),
		cash_acct_code varchar(32),
		date_doc int,
		payment_code varchar(8),
		payment_type smallint,
		amt_applied float,
		amt_disc_taken float,
		printed_flag smallint,
		hold_flag smallint,
		nat_cur_code varchar(8),
		rate_type_home varchar(8),
		rate_type_oper varchar(8),
		rate_home float,
		rate_oper float,
		inserted int,
		org_id varchar(30) NULL
    )






INSERT #pay_header  (
		vendor_code,
		pay_to_code,		
		cash_acct_code,
		doc_ctrl_num,
		date_doc,
		payment_code,
		payment_type,
		amt_applied,
		amt_disc_taken,
		printed_flag,
		hold_flag,
		nat_cur_code,
		rate_type_home,
		rate_type_oper,
		rate_home,
		rate_oper,
		inserted )
SELECT 
		vendor_code,
		pay_to_code,
	    cash_acct_code,
		doc_ctrl_num,
		0,
		"",
		2,
		SUM(amt_applied),
		SUM(amt_disc_taken),
		2,
		0,
		"",
		"",
		"",
		0.0,
		0.0,
		0
FROM #pay_detail 
GROUP BY vendor_code, pay_to_code, cash_acct_code, doc_ctrl_num	

IF @@error <> 0
   RETURN -1





UPDATE #pay_header
SET date_doc = b.date_doc,
    payment_code = b.payment_code,
	nat_cur_code = b.nat_cur_code,
	rate_type_home = b.rate_type_home,
	rate_type_oper = b.rate_type_oper,
	rate_home = b.rate_home,
    rate_oper = b.rate_oper,
	org_id = b.org_id,				
	payment_type = a.payment_type * SIGN(ABS(3-b.payment_type)) +
				   b.payment_type * ABS(SIGN(ABS(3-b.payment_type))-1)			
FROM #pay_header a, #apgooa b
WHERE a.cash_acct_code = b.cash_acct_code
AND   a.doc_ctrl_num = b.doc_ctrl_num

IF @@error <> 0
   RETURN -1


DROP TABLE #apgooa


IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "apgenona.cpp" + ", line " + STR( 255, 5 ) + " -- MSG: " + "---Insert records through the interface"





WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		SELECT 	@vendor_code = vendor_code,
		        @pay_to_code = pay_to_code,
				@cash_acct_code = cash_acct_code,
				@doc_ctrl_num = doc_ctrl_num,
				@doc_date = date_doc,
				@payment_code = payment_code,
				@payment_type = payment_type,
				@amt_applied = amt_applied,
				@amt_disc_taken = amt_disc_taken,
				@printed_flag = printed_flag,
				@hold_flag = hold_flag,
				@nat_cur_code = nat_cur_code,
				@rate_type_home = rate_type_home,
				@rate_type_oper = rate_type_oper,
				@rate_home = rate_home,
				@rate_oper = rate_oper,
				@org_id = org_id			
		FROM #pay_header
		WHERE inserted = 0
	  
	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0



		SELECT @pyt_num = NULL
		EXEC @result = appycrh_sp 	4000,  	
									2,	
									@pyt_num OUTPUT,
									4111,		
									@doc_ctrl_num,		
									" ",		  
									" " ,	
									@cash_acct_code,	
									@current_date,	 
									@date_applied,	
				  					@doc_date,		
				  					@vendor_code,		
				  					@pay_to_code,		
				  					@approval_code,	
				  					@payment_code,		
				  					@payment_type,	
				  					@amt_applied,		
				  					0.0,				
				  					0,		
				  					@printed_flag ,	
				  					@hold_flag ,
				  					0 ,	
				  					@gen_id ,	
				  					@user_id,
				  					0 ,	
				  					@amt_disc_taken,	
				  					0 ,
				  					@company_code,	
				  					'',
									@nat_cur_code,
									@rate_type_home,
									@rate_type_oper,
									@rate_home,
									@rate_oper,
									@org_id				


		IF @result <> 0
		   RETURN @result

				 SELECT @seq_id = 1
				 WHILE (1=1)
					BEGIN
						 SET ROWCOUNT 1
						 
						 SELECT @apply_to_num = apply_to_num,
						 	   @amt_applied = amt_applied,
						 	   @amt_disc_taken = amt_disc_taken,
							   @vo_amt_applied = vo_amt_applied,
							   @vo_amt_disc_taken = vo_amt_disc_taken,
							   @gain_home = gain_home,
							   @gain_oper = gain_oper,
							   @nat_cur_code = nat_cur_code,
							   @org_id_vo =  org_id
						 FROM #pay_detail
						 WHERE vendor_code = @vendor_code
						 AND   pay_to_code = @pay_to_code
						 AND   cash_acct_code = @cash_acct_code
						 AND   doc_ctrl_num = @doc_ctrl_num
						 AND   inserted = 0

						 IF @@rowcount = 0 BREAK
						 SET ROWCOUNT 0	



						  EXEC @result = appycrd_sp 4000,
						  2,	
						  @pyt_num,		
						  4111,	
						  @seq_id ,	
						  @apply_to_num,
						  4091,		
						  @amt_applied,		
						  @amt_disc_taken,
						  " ",	 	
						  0 ,	
						  0 ,	
						  @vendor_code,
						  @vo_amt_applied,
						  @vo_amt_disc_taken,
						  @gain_home,
						  @gain_oper,
						  @nat_cur_code,
						  @org_id_vo

						  IF @result <> 0
						     RETURN @result

						  UPDATE #pay_detail
						  SET inserted = 1
						  WHERE vendor_code = @vendor_code
						  AND   pay_to_code = @pay_to_code
						  AND   cash_acct_code = @cash_acct_code
						  AND   doc_ctrl_num = @doc_ctrl_num
						  AND   apply_to_num = @apply_to_num
						  AND   inserted = 0

						  IF @@error <> 0
   						   RETURN -1

						  SELECT @seq_id = @seq_id + 1
			 END
        SET ROWCOUNT 0


		UPDATE #pay_header
		SET inserted = 1
		WHERE vendor_code = @vendor_code
		AND pay_to_code = @pay_to_code
		AND cash_acct_code = @cash_acct_code
		AND doc_ctrl_num = @doc_ctrl_num
		AND org_id = @org_id  

		IF @@error <> 0
		   RETURN -1

   END
SET ROWCOUNT 0


DROP TABLE #pay_header
DROP TABLE #pay_detail


RETURN 0


GO
GRANT EXECUTE ON  [dbo].[apgenona_sp] TO [public]
GO
