SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





CREATE PROC [dbo].[APVOProcessPayments_sp]    	@process_group_num	varchar(16),
									    @debug_level smallint = 0

AS
	DECLARE
			@trx_ctrl_num varchar(16),
			@pay_ctrl_num varchar(16),
  			@doc_ctrl_num varchar(16),		
  			@trx_desc varchar(40),
			@cash_acct_code varchar(32),	
			@date_entered int,
			@date_applied int,	
			@date_doc int,		
			@vendor_code varchar(12),
			@pay_to_code varchar(8),		
			@approval_code varchar(8),		
			@payment_code varchar(8),
			@payment_type smallint,	
			@amt_payment float,		
			@amt_on_acct float,
			@user_id smallint,
			@amt_disc_taken float,	
			@company_code varchar(8),	
			@amt_applied float,
			@nat_cur_code varchar(8),
			@rate_type_home varchar(8),
			@rate_type_oper varchar(8),
			@rate_home float,
			@rate_oper float,
			@gain_home float,
			@gain_oper float,
			@home_precision smallint,
			@oper_precision smallint,
			@result int,
			@org_id	varchar(30)

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopp.cpp' + ', line ' + STR( 84, 5 ) + ' -- ENTRY: '


SELECT @company_code = a.company_code,
	   @home_precision = b.curr_precision,
	   @oper_precision = c.curr_precision
FROM glco a, glcurr_vw b, glcurr_vw c
WHERE a.home_currency = b.currency_code
AND a.oper_currency = c.currency_code


CREATE TABLE #pyheader (
						trx_ctrl_num varchar(16),
			  			doc_ctrl_num varchar(16),		
			  			trx_desc varchar(40),
						cash_acct_code varchar(32),	
						date_entered int,
						date_applied int,	
						date_doc int,		
						vendor_code varchar(12),
						pay_to_code varchar(8),		
						approval_code varchar(8),		
						payment_code varchar(8),
						payment_type smallint,	
						amt_payment float,		
						amt_on_acct float,
						user_id smallint,
						amt_disc_taken float,	
						amt_applied float,
						nat_cur_code varchar(8),
						rate_type_home varchar(8),
						rate_type_oper varchar(8),
						rate_home float,
						rate_oper float,
						gain_home float,
						gain_oper float,
						org_id varchar(30) NULL,
						mark_flag smallint
						)



INSERT #pyheader (
						trx_ctrl_num,
			  			doc_ctrl_num,
			  			trx_desc,
						cash_acct_code,
						date_entered,
						date_applied,
						date_doc,
						vendor_code,
						pay_to_code,
						approval_code,
						payment_code,
						payment_type,
						amt_payment,
						amt_on_acct,
						user_id,
						amt_disc_taken,
						amt_applied,
						nat_cur_code,
						rate_type_home,
						rate_type_oper,
						rate_home,
						rate_oper,
						gain_home,
						gain_oper,
						org_id,
						mark_flag
						)
SELECT   				a.trx_ctrl_num,
			  			a.doc_ctrl_num,
			  			a.trx_desc,
						a.cash_acct_code,
						b.date_entered,
						a.date_applied,
						a.date_doc,
						a.vendor_code,
						b.pay_to_code,
						b.approval_code,
						a.payment_code,
						a.payment_type,
						a.amt_payment,
						0.0,
						a.user_id,
						a.amt_disc_taken,
						a.amt_payment,
						b.nat_cur_code,
						b.rate_type_home,
						b.rate_type_oper,
						b.rate_home,
						b.rate_oper,
						0.0,
						0.0,
						b.org_id,
						0

FROM #apvotmp_work a, #apvochg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND ((a.amt_payment) > (0.0) + 0.0000001)


UPDATE #pyheader
SET amt_on_acct = a.amt_payment - b.amt_net,
    amt_applied = b.amt_net
FROM #pyheader a, #apvochg_work b
WHERE a.trx_ctrl_num = b.trx_ctrl_num
AND ((a.amt_payment) > (b.amt_net) + 0.0000001)

UPDATE #pyheader
SET gain_home = (SIGN(a.amt_applied * a.rate_home - a.amt_applied * b.rate_home) * ROUND(ABS(a.amt_applied * a.rate_home - a.amt_applied * b.rate_home) + 0.0000001, @home_precision)),
	gain_oper =	(SIGN(a.amt_applied * a.rate_oper - a.amt_applied * b.rate_home) * ROUND(ABS(a.amt_applied * a.rate_oper - a.amt_applied * b.rate_home) + 0.0000001, @oper_precision))
FROM #pyheader a, appyhdr b
WHERE a.doc_ctrl_num = b.doc_ctrl_num
AND a.cash_acct_code = b.cash_acct_code
AND a.payment_type = 2


WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT 	@trx_ctrl_num = trx_ctrl_num,
	  				@doc_ctrl_num = doc_ctrl_num,
	  				@trx_desc = trx_desc,
					@cash_acct_code = cash_acct_code,
					@date_entered = date_entered,
					@date_applied = date_applied,	
					@date_doc = date_doc,		
					@vendor_code = vendor_code,
					@pay_to_code = pay_to_code,
					@approval_code = approval_code,
					@payment_code = payment_code,
					@payment_type = payment_type,	
					@amt_payment = amt_payment,		
					@amt_on_acct = amt_on_acct,
					@user_id = user_id,
					@amt_disc_taken = amt_disc_taken,
					@amt_applied = amt_applied,
					@nat_cur_code = nat_cur_code,
					@rate_type_home = rate_type_home,
					@rate_type_oper = rate_type_oper,
					@rate_home = rate_home,
					@rate_oper = rate_oper,
					@gain_home = gain_home,
					@gain_oper = gain_oper,
					@org_id		= org_id
		  FROM #pyheader
		  WHERE mark_flag = 0
	  
	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

			SELECT @pay_ctrl_num = NULL	      
	
			EXEC @result = appycrh_sp
							4000,		
							2,		
							@pay_ctrl_num OUTPUT,
				  			4111,		
				  			@doc_ctrl_num,		
				  			@trx_desc,
							'',	
							@cash_acct_code,	
							@date_entered,
							@date_applied,	
							@date_doc,		
							@vendor_code,
							@pay_to_code,		
							@approval_code,		
							@payment_code,
							@payment_type,	
							@amt_payment,		
							@amt_on_acct,
							-1,		
							2,	
							0,
							0,	
							0,		
							@user_id,
							0,	
							@amt_disc_taken,	
							0,
							@company_code,	
							@process_group_num,
							@nat_cur_code,
							@rate_type_home,
							@rate_type_oper,
							@rate_home,
							@rate_oper,
							@org_id
   			
   			IF  (@result != 0)
				RETURN @result


				EXEC @result = appycrd_sp
									4000,
									2,	
									@pay_ctrl_num,		
									4111,	
								  	1,	
								  	@trx_ctrl_num,
					  				4091,		
					  				@amt_applied,		
					  				@amt_disc_taken,	
					  				@trx_desc,	 	
					  				0,	
					  				0,
					  				@vendor_code,
									@amt_applied,
									@amt_disc_taken,
									@gain_home,
									@gain_oper,
									@nat_cur_code,
									@org_id

			IF  (@result != 0)
				RETURN @result


			SET ROWCOUNT 1
			UPDATE #pyheader		    
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

DROP TABLE #pyheader

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apvopp.cpp' + ', line ' + STR( 316, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APVOProcessPayments_sp] TO [public]
GO
