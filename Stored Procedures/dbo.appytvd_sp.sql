SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                
































































































































  



					  

























































 

































































































































































































































































































CREATE  PROCEDURE [dbo].[appytvd_sp]    
	@x_posted_flag 	smallint,     
	@x_sys_date 	int,        
	@call_flag		smallint,
	@x_proc_key		smallint,   
	@x_user_id		smallint,    
	@x_orig_flag	smallint
AS




DECLARE @trx_num        varchar(16),	@sqid           	int,    
		@apply_type     smallint,       @last_sqid      	int,            
		@apply_num      varchar(16),    @amt_applied    	float,  
		@amt_disc       float,			@line_desc      	varchar(40),
		@void_flag      smallint,			@total_trx      	float,  
		@trx_done       float,			@perc_done      	float,
		@posted_flag    smallint,			@batch_flag     	smallint,
		@amt_payment    float,         @batch_code     	varchar(16),
		@doc_ctrl_num   varchar(16),   @cash_acct_code 	varchar(32),
		@vo_amt_applied	float,			@vo_amt_disc_taken	float,
		@gain_home		float,			@gain_oper			float,
		@str_msg varchar(255)
	


SELECT @batch_flag = batch_proc_flag FROM apco





IF      @call_flag = 0
BEGIN
	SELECT  @void_flag = 1  
	SELECT  @posted_flag = 0
END
ELSE
BEGIN
	SELECT  @void_flag = 2  
	SELECT  @posted_flag = @x_posted_flag
END




SELECT  @total_trx = 0.0, @trx_done = 0.0

SELECT  @total_trx = COUNT( trx_ctrl_num )
FROM    appytprn_vw
WHERE   posted_flag = @x_posted_flag




IF ( (ABS((@total_trx)-(0.0)) < 0.0000001) )
BEGIN
	IF @call_flag = 0
	BEGIN 

	   EXEC appgetstring_sp "STR_NO_TRANS_VOID", @str_msg OUT

	   EXEC status_sp "APPYTVD", @x_proc_key, @x_user_id,
		@str_msg, 100, @x_orig_flag, 0
	END
	RETURN
END





IF @call_flag = 0
BEGIN
	EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT
	EXEC status_sp  "APPYTVD", @x_proc_key, @x_user_id,
		@str_msg, 0, @x_orig_flag, 0
END

WHILE ( 1 = 1 )
BEGIN
	


	SELECT  @trx_num = NULL
	SELECT  @trx_num = min( trx_ctrl_num )
	FROM    appytprn_vw
	WHERE   posted_flag = @x_posted_flag

	IF ( @trx_num IS NULL )
	BEGIN
	   IF @call_flag = 0
	   BEGIN
		EXEC appgetstring_sp "STR_PROCESSING_COMP", @str_msg OUT
		EXEC status_sp  "APPYTVD", @x_proc_key, @x_user_id,
				@str_msg, 100, @x_orig_flag, 0
	   END
	   RETURN
	END

	BEGIN TRAN
	


	INSERT  apvchdr (
				trx_ctrl_num,
				doc_ctrl_num,
				batch_code,
				date_applied,
				date_doc,
				date_entered,
				vendor_code,
				pay_to_code,
				cash_acct_code,
				payment_code,
				state_flag,
				void_flag,
				amt_net,
				amt_discount,
				user_id,
				print_batch_num,
				process_ctrl_num,
				currency_code
	)
	SELECT
	   @trx_num,            
	   doc_ctrl_num,
	   batch_code,
	   date_applied,
	   date_doc,            
	   @x_sys_date,
	   vendor_code,         
	   pay_to_code,
	   cash_acct_code,
	   payment_code,
	   1,
	   @void_flag,
	   amt_payment,            
	   amt_disc_taken,
	   user_id,     
	   print_batch_num,     
	   "",
	   nat_cur_code
	FROM    appytprn_vw
	WHERE   trx_ctrl_num = @trx_num

	SELECT @doc_ctrl_num = doc_ctrl_num,
		   @cash_acct_code = cash_acct_code
	FROM  appytprn_vw
	WHERE trx_ctrl_num = @trx_num
	
	
	






		























		










		


	





















	




	IF      @call_flag = 0
	BEGIN
		
		if @batch_flag = 1
		   BEGIN
			SELECT @batch_code = batch_code,
			       @amt_payment = amt_payment
			FROM appytprn_vw
			WHERE trx_ctrl_num = @trx_num

			UPDATE batchctl
			SET actual_number = actual_number - 1,
			    actual_total = actual_total - @amt_payment
			FROM batchctl
			WHERE batch_ctrl_num = @batch_code
		   
		   END
		
		
		
		



		DELETE  apinppdt
		WHERE   trx_ctrl_num = @trx_num

		DELETE  appytprn_vw
		WHERE   trx_ctrl_num = @trx_num


		     
		

		DELETE  apchkstb
		WHERE   payment_num = @trx_num

		

		DELETE apexpdst
		WHERE  payment_num = @trx_num

		DELETE  apaprtrx
		WHERE   trx_ctrl_num = @trx_num
		AND     trx_type = 4111
	
	
	END
	ELSE
	BEGIN

		




		UPDATE  appytprn_vw
		SET     printed_flag = 0, doc_ctrl_num = " "
		WHERE   trx_ctrl_num = @trx_num

	END

	


	UPDATE apchkdsb
	SET check_num = "",
	    cash_acct_code = "",
		check_ctrl_num = ""
	WHERE check_num = @doc_ctrl_num
	AND cash_acct_code = @cash_acct_code



	COMMIT TRAN

	



	SELECT  @trx_done = @trx_done + 1
	SELECT  @perc_done = @trx_done / @total_trx * 100

	EXEC appgetstring_sp "STR_PROCESSING", @str_msg OUT
	EXEC status_sp "APVOUTRX", @x_proc_key, @x_user_id,
		@str_msg, @perc_done, @x_orig_flag, 0
	
END


GO
GRANT EXECUTE ON  [dbo].[appytvd_sp] TO [public]
GO
