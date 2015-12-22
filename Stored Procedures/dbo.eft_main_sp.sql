SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2009 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2009 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                































CREATE PROC [dbo].[eft_main_sp]
@rerun_flag						smallint ,
@eft_batch_num 					int ,
@cash_acct_code		       		char(32) ,
@payment_code	          		varchar(8),
@company_entry_description 		char(10),
@descriptive_date				int,
@effective_date					int	,
@addenda_flag					smallint ,
@file_fmt_code					varchar(8),
@debug 							smallint,
@rb_processing_centre			char(5)   

		
   
AS  DECLARE 
@tax_id_num 			 char(10) ,
@company_name_apco		 char(30), 
@bank_account_num		 char(20),
@bank_name       		 char(40),
@bank_aba_number 		 char(16),
@result					 smallint ,
@tran_started 			 smallint ,
@run_sequence			 int   ,
@run_date				 datetime ,
@user_id				 smallint  ,
@value_of_trans			 float,
@number_of_trans         float,
@originator_status_code	 char(1),
@company_identification	 char(10) ,
@company_data			 char(20),
@file_id				 varchar(1)	,
@check_date				 smallint ,
@date					 char(10) ,
@process_date			 int ,
@year					 int,
@month 					 int,
@day					 int,
@system_date			 char(10),
@transaction_code		 char(3),
@nat_cur_code			 varchar(8)


		

		


		
		DELETE FROM eft_temp

		


		
		SELECT @tran_started = 0 ,
		       @run_sequence = 1 ,
			   @user_id = user_id()	,
			   @value_of_trans = 0
			   	
	
	   
	   
	   

		SELECT @system_date = convert(char(10), getdate(),101)

		SELECT @process_date= 0

		SELECT @year = convert(int,substring (@system_date,7,4)) 

		SELECT @month = convert(int,substring (@system_date,1,2))

		SELECT @day = convert(int,substring (@system_date,4,2))

		EXEC appjuldt_sp @year,@month,@day, @process_date  OUTPUT

	  
BEGIN TRANSACTION	  

SELECT @tran_started = 1 


		


		 
		SELECT @tax_id_num  = ltrim(substring (tax_id_num, 1,10) )	,
		       @company_name_apco= ltrim(substring(company_name, 1,30)) 
		FROM apco

		IF @tax_id_num IS NULL
		
		BEGIN

		RETURN 1039

	   	IF (@debug > 0 )  
   		BEGIN
	 		SELECT "*** eft)_main_sp - No record in apco table!"
 		END    

		END

IF (@rerun_flag = 0 )

BEGIN 


		


		
		 	   		 
		SELECT @eft_batch_num = next_eft_batch_number ,
			   @originator_status_code = convert(char(1),
			   							 originator_status_code) ,
			   @company_identification = substring(company_identification,1,10),
			   @transaction_code	   = ltrim(substring(
			   							 transaction_code,1,3))
		FROM  eft_pymeth
		WHERE payment_code = @payment_code


		UPDATE eft_pymeth
		SET next_eft_batch_number =  @eft_batch_num	 + 1
		WHERE payment_code = @payment_code
        
	   

		


		
	   		 
		SELECT @bank_account_num = a.bank_account_num	,
			 @bank_name = a.bank_name ,			 
			 @bank_aba_number = a.aba_number,
			 @nat_cur_code	 = b.nat_cur_code
			   
		FROM apcash a, apinppyt b
		WHERE a.cash_acct_code = @cash_acct_code AND b.cash_acct_code = @cash_acct_code

	   		
		IF @bank_account_num IS NULL
		BEGIN
		
		RETURN 1039
							  
		IF (@debug > 0 ) 
		BEGIN 
 		SELECT "*** eft)_main_sp - No record in apcash table +
 		       for cash_ccount code: " +@cash_acct_code + " !"
 		END    

		END
	
	
		

 

		
		UPDATE eft_aptr
		SET eft_batch_num = @eft_batch_num,
			process_date  = @process_date
		WHERE  cash_acct_code =  @cash_acct_code
	   	AND    payment_code   =  @payment_code
		AND    process_flag   =  0

	   

		IF ( @@error != 0 )
  	
 		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 ) 
  	   	SELECT "*** eft_main_sp - Database Error Updating EFT  +
 		       Transaction Table!" 
 		RETURN 1039
    	END    
    	
    	
    	

 

		UPDATE apchkdsb
		SET check_ctrl_num  ="EFT" + substring(str(100000000 +@eft_batch_num,9),2,8)
		FROM apchkdsb a, eft_aptr b 
		WHERE  a.trx_ctrl_num = b.doc_ctrl_num
		AND    a.check_ctrl_num = " "
	   

		IF ( @@error != 0 )
  	
 		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 ) 
  	   	SELECT "*** eft_main_sp - Database Error Updating apchkdsb
 		        Table!" 
 		RETURN 1039
    	END    	  
    	

    		  
    	
		


 

	   	SELECT @date = convert(char(10),getdate(),101)


		SELECT @check_date = count(*)
		FROM eft_run
		WHERE convert(char(10),run_date,101) = @date
		AND cash_account_code = @cash_acct_code
 

		IF @check_date IS NULL
		SELECT @file_id = '0'
		ELSE
		BEGIN
		SELECT @file_id = convert(char(1),@check_date + 1)
		END


  END


   	ELSE
	
	BEGIN

		SELECT 
			   @originator_status_code = convert(char(1),
			   							 originator_status_code) ,
			   @company_identification = ltrim(substring(
			                             company_identification,1,10)),
			   @transaction_code	   = ltrim(substring(
			   							 transaction_code,1,3))
		FROM  eft_pymeth
		WHERE payment_code = @payment_code

		


  
  		SELECT 
			   @cash_acct_code = cash_account_code ,
			   @payment_code   = payment_code ,
			   @bank_account_num = orig_account_num	,
			   @bank_name        = orig_bank_name  ,
			   @bank_aba_number  = orig_aba_num	,
			   @run_sequence	 = run_sequence
			         
			   
		FROM   eft_run
		WHERE  eft_batch_num = @eft_batch_num
	      AND   payment_code = @payment_code


		IF @rb_processing_centre = ' '
		BEGIN
		SELECT
		@rb_processing_centre	= rb_processing_centre	 
		FROM   eft_run
		WHERE  eft_batch_num = @eft_batch_num
		AND   payment_code = @payment_code

		END

		IF @company_entry_description = ' '
		BEGIN
		SELECT
		@company_entry_description	= company_entry_description	 
		FROM   eft_run
		WHERE  eft_batch_num = @eft_batch_num
		AND   payment_code = @payment_code

		END
		
		IF 	@descriptive_date	= 0							  
		BEGIN
		SELECT
		@descriptive_date = company_descriptive_date	
		FROM   eft_run
		WHERE  eft_batch_num = @eft_batch_num
		AND   payment_code = @payment_code

		END


		IF 	@effective_date	= 0							  
		BEGIN
		SELECT
		@effective_date	 = effective_entry_date 
		FROM   eft_run
		WHERE  eft_batch_num = @eft_batch_num
		AND   payment_code = @payment_code

		END
 


END   		

		
		SELECT @company_data = 'EFT BATCH #  '  +
			                   convert(char(7), @eft_batch_num )

	    IF (@debug > 0 )  
		BEGIN
 		SELECT "*** eft_main_sp - Call eft_file"
		SELECT @eft_batch_num
 		END    		  


		



	IF (@file_fmt_code IN('CTX','PPD','CCD'))

	BEGIN

			

 

				EXEC @result = eft_file_sp
				@eft_batch_num 					,
				@cash_acct_code		       		,
				@tax_id_num 			 		,
				@company_name_apco		 		,
				@payment_code	          		,
				@bank_account_num				,
				@bank_name       		 		,
				@bank_aba_number 		 		,
				@company_entry_description 		,
				@descriptive_date				,
				@effective_date					,
				@addenda_flag					,
				@value_of_trans					OUTPUT,
				@originator_status_code		    ,
				@company_identification		   	,
				@company_data				  	,
				@file_id					  	,
				@debug 						  	,
				@file_fmt_code					  

	END        		


	IF (@file_fmt_code = 'CPA005CR')	

	BEGIN

			

 

				EXEC @result = eft_cpa_sp
				@eft_batch_num 					,
				@cash_acct_code		       		,
				@company_name_apco		 		,
				@payment_code	          		,
				@company_entry_description 		,
				@effective_date					,
				@value_of_trans					OUTPUT,
				@company_identification		   	,
				@transaction_code		 		,
				@debug 							,
				@rb_processing_centre	

	END        		


	IF (@file_fmt_code = 'EXPRESS')	

	BEGIN

			

 

				EXEC @result = eft_exp_sp
				@eft_batch_num,
				@cash_acct_code,
				@payment_code,
				@effective_date,
				@value_of_trans  OUTPUT,
				@debug 	   

	END        		


        IF ( @@error != 0 )
  		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 )  
 		SELECT "*** eft_main_sp - Database Error Updating EFT table!" 
 		RETURN 1039
    	END    		  

		IF ( @result != 0 )
  	
  		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 )  
 		SELECT "*** eft_main_sp - Database Error Updating eft_temp table!" 
 		RETURN 1039
    	END    	


		
		IF ( @debug > 0 ) 
		BEGIN
 		SELECT "*** eft_main_sp - Called eft_file_sp" 
 		END 

		
IF (@rerun_flag = 0 )

BEGIN	

		

 


		UPDATE apinppyt
		SET hold_flag = 0
		FROM apinppyt , eft_aptr
		WHERE payment_num = trx_ctrl_num
		AND   eft_batch_num = @eft_batch_num

		
	 	IF ( @@error != 0 )
  	
  		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 )  
 		SELECT "*** eft_main_sp - Database Error Updating payment table!" 
 		RETURN 1039
    	END    		

		

 

		SELECT @number_of_trans = count(distinct(payment_num) )
		FROM   eft_aptr
 		WHERE  eft_batch_num = @eft_batch_num
		AND   payment_code = @payment_code

	
	    INSERT eft_run

		( eft_batch_num	 ,  run_sequence ,				
		  run_date	,	  value_of_trans  ,				
		  number_of_trans , payment_code  ,				
		  cash_account_code	 ,
		  rb_processing_centre	,		
		  company_entry_description,
		  company_descriptive_date ,	
		  effective_entry_date	   ,	
		  addenda_flag			   ,	
		  orig_account_num		   ,	
		  orig_bank_name		   ,		
		  orig_aba_num			   ,	
		  user_id				   ,
		  nat_cur_code				)
		  		

		VALUES (
		  @eft_batch_num	 ,  @run_sequence ,				
		  getdate()	,	  @value_of_trans  ,				
		  @number_of_trans , @payment_code  ,				
		  @cash_acct_code	 ,
		  @rb_processing_centre  ,				
		  @company_entry_description,
		  @descriptive_date ,	
		  @effective_date	   ,	
		  @addenda_flag			   ,	
		  @bank_account_num   ,
		  @bank_name           ,
		  @bank_aba_number  	,
		  @user_id,
		  @nat_cur_code				   )

	   	IF (@debug > 0 ) 
	   	BEGIN 
 		SELECT "*** eft_main_sp - Updated eft_run !" 
 		END   	   	
	   

END   		


ELSE

BEGIN

	    

 


	  	UPDATE 	eft_run
	  	SET		run_sequence = @run_sequence  + 1	,
	        	run_date     = getdate() ,
			 	user_id	  = user_id ,
				rb_processing_centre  = @rb_processing_centre  ,		
			 	company_entry_description	= @company_entry_description	 ,
			 	company_descriptive_date   = @descriptive_date	,
			 	effective_entry_date		= @effective_date ,
			 	addenda_flag		        = @addenda_flag
	  	WHERE  	eft_batch_num = @eft_batch_num 
	  	AND   	payment_code = @payment_code
	
	    IF ( @@error != 0 )
  		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 )  
 		SELECT "*** eft_main_sp - Database Error Updating EFT RUN table!" 
 		RETURN 1039
    	END    

	  
	  END

	  
		


 

		UPDATE eft_temp
		SET cr_flag = 0
		WHERE  cr_flag =  NULL

	   

		IF ( @@error != 0 )
  	
 		BEGIN 
  		IF ( @tran_started = 1 ) 
  		ROLLBACK TRAN
  		IF (@debug > 0 ) 
 		SELECT "*** eft_main_sp - Database Error Updating eft_temp table!" 
 		RETURN 1039
    	END    


  	 BEGIN 
 	    COMMIT TRANSACTION  
 		SELECT @tran_started = 0  
 	 END    			 

		BEGIN
 		IF ( @debug > 0 ) 
 		SELECT "*** eft_main_sp - EFT file generated successfull" 
 		RETURN @result
 		END



GO
GRANT EXECUTE ON  [dbo].[eft_main_sp] TO [public]
GO
