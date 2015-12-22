SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







CREATE PROC [dbo].[APDMProcessPayments_sp]    	@process_group_num	varchar(16),
										@user_id int,
										@debug_level smallint = 0

AS
	DECLARE
			@trx_ctrl_num varchar(16),
			@apply_to_num           varchar(16),
			@current_date int,
			@result int,
			@pay_ctrl_num varchar(16),
			@company_code varchar(8),
			@trx_desc                       varchar(40),
			@vendor_code        varchar(12),
			@pay_to_code        varchar(8),
			@date_entered	int,
			@date_applied	int,
			@date_doc		int,
			@amt_payment            float,
			@amt_on_acct            float,
			@amt_disc_taken         float,
			@amt_applied         float,
		    @nat_cur_code	varchar(8),
			@rate_type_home	varchar(8),
			@rate_type_oper	varchar(8),
			@rate_home	float,
			@rate_oper	float,
			@approval_code varchar(8),
			@approval_flag smallint,
			@org_id		varchar(30)



IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdmpp.cpp' + ', line ' + STR( 86, 5 ) + ' -- ENTRY: '


EXEC appdate_sp @current_date OUTPUT
SELECT @company_code = company_code FROM glco
SELECT @approval_code = default_aprv_code,
	   @approval_flag = aprv_check_flag
FROM apco

IF @approval_flag = 0
	SELECT @approval_code = ''


CREATE TABLE #pyheader (
						trx_ctrl_num varchar(16),
						apply_to_num varchar(16),
						trx_desc                       varchar(40),
						vendor_code        varchar(12),
						pay_to_code        varchar(8),
						date_entered		int,
						date_applied		int,
						date_doc			int,
						amt_payment            float,
						amt_on_acct            float,
						amt_applied			float,
					    nat_cur_code	varchar(8),
						rate_type_home	varchar(8),
						rate_type_oper	varchar(8),
						rate_home	float,
						rate_oper	float,
						org_id		varchar(30) NULL,
						mark_flag smallint
						)



INSERT #pyheader (
						trx_ctrl_num,
						apply_to_num,
						trx_desc,
						vendor_code,
						pay_to_code,
						date_entered,
						date_applied,
						date_doc,
						amt_payment,
						amt_on_acct,
						amt_applied,
					    nat_cur_code,
						rate_type_home,
						rate_type_oper,
						rate_home,
						rate_oper,
						org_id,
						mark_flag
						)
SELECT   trx_ctrl_num,
		 apply_to_num,
         doc_desc,
		 vendor_code,
		 pay_to_code,
		 date_entered,
		 date_applied,
		 date_doc,
		 amt_net,
		 0.0,
		 amt_net,
	     nat_cur_code,
		 rate_type_home,
		 rate_type_oper,
		 rate_home,
		 rate_oper,
		org_id,
		 0
FROM #apdmchg_work 
WHERE apply_to_num != ''
									    


UPDATE #pyheader
SET amt_applied = b.amt_net - b.amt_paid_to_date,
	amt_on_acct = #pyheader.amt_payment - (b.amt_net - b.amt_paid_to_date)
FROM #pyheader, #apdmxv_work b
WHERE #pyheader.apply_to_num = b.trx_ctrl_num
AND ((#pyheader.amt_payment) > ((b.amt_net - b.amt_paid_to_date)) + 0.0000001)


DELETE FROM #pyheader WHERE ((amt_applied) <= (0.0) + 0.0000001)


WHILE (1=1)
   BEGIN
	  SET ROWCOUNT 1
		  SELECT 	@trx_ctrl_num = trx_ctrl_num,
					@apply_to_num = apply_to_num,
					@trx_desc = trx_desc,
					@vendor_code = vendor_code,
					@pay_to_code = pay_to_code,
					@date_entered = date_entered,
					@date_applied = date_applied,
					@date_doc = date_doc,
					@amt_payment = amt_payment,
					@amt_on_acct = amt_on_acct,
					@amt_applied = amt_applied,
				    @nat_cur_code = nat_cur_code,
					@rate_type_home = rate_type_home,
					@rate_type_oper = rate_type_oper,
					@rate_home = rate_home,
					@rate_oper = rate_oper,
					@org_id = org_id
 FROM #pyheader
		  WHERE mark_flag = 0
	  
	  
	  	  IF @@rowcount = 0 BREAK
	  
	  SET ROWCOUNT 0

			SELECT @pay_ctrl_num = NULL	      



	declare @batch_flag smallint, 	
		@batch_ctrl_num char(16) 

	if (select batch_proc_flag from apco) = 1
		exec apbatnum_sp @batch_flag  OUTPUT, 	@batch_ctrl_num  OUTPUT 	
	else
		select @batch_ctrl_num = ' '	


	
			EXEC @result = appycrh_sp
					   4000,
					   2,
					   @pay_ctrl_num  OUTPUT,
				   	   4111,
					   @trx_ctrl_num,
					   @trx_desc,
					   @batch_ctrl_num,         
					   ' ',
					   @date_entered,
					   @date_applied,
					   @date_doc,
				   	   @vendor_code,
					   @pay_to_code,
					   @approval_code,
					   ' ',
					   3,
				   	   @amt_payment,
					   @amt_on_acct,
					   -1, 
					   2,
					   0,
					   0,
					   0,
					   @user_id,
					   0,
					   0,
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

				
				--declare @dt_org_id varchar(30)
				--select @dt_org_id = org_id from #apdmcdt_work
				

				EXEC @result = appycrd_sp
					   4000,
					   2,
					   @pay_ctrl_num,
					   4111,
					   1,
					   @apply_to_num,
					   4091,
					   @amt_applied,
					   0.0,
					   @trx_desc,
					   0,
					   0,
					   @vendor_code,
					   @amt_applied,
					   0.0,
					   0.0,
					   0.0,
					   @nat_cur_code,
					   @org_id	--SCR # 050376 / RiGarcia / 06-26-2008
			
			IF  (@result != 0)
				RETURN @result


			SET ROWCOUNT 1
			UPDATE #pyheader		    
			SET mark_flag = 1
			WHERE mark_flag = 0
			SET ROWCOUNT 0

	END

DROP TABLE #pyheader

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'apdmpp.cpp' + ', line ' + STR( 294, 5 ) + ' -- EXIT: '
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[APDMProcessPayments_sp] TO [public]
GO
