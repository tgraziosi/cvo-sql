SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_ctx.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[eft_ctx_sp]
@sequence						smallint,
@addenda_flag smallint,
@transaction_code char(2),
@vendor_aba_number 				char(16),
@vendor_bank_acct_num 		 char(20),
@payment_amount 		char(10) ,
@company_entry_description 		char(10),
@vendor_code				 char(12),
@vendor_name					char(40),
@bank_aba_number 				char(16), 
@payment_num					char(16),
@check_digit					char(1)	,
@file_fmt_code					varchar(8),
@individual_name				char(22),
@debug							smallint
		
 
AS DECLARE 
@entry_detail_sequence	 		char(7) ,
@voucher_num 		char(16),
@addenda_sequence_number 		char(4) ,
@addenda_record_indicator 		char(1) ,
@description					char(80) ,
@result							smallint,
@addenda_number					smallint ,
@sequence_id					int	,
@last_sequence_id				int	,
@count_det						smallint	
	
	 	
		
		
		SELECT
		@last_sequence_id = -1 ,
	 	@sequence_id = 0 ,
		@count_det = 0,
		@addenda_record_indicator = '0'	,
		@addenda_number	= 0	,
 @addenda_sequence_number =
			 substring (CONVERT (char(5),0+(10000)),2,4) 



		IF (@debug > 0)
			BEGIN
			SELECT " Addenda count "
			SELECT @addenda_sequence_number 
			END
 



	 	

		SELECT @count_det = count(*) + 1 
		FROM eft_temp
	 	WHERE record_type_code = '6'
		AND addenda_count = 0

		IF @count_det IS NULL
		SELECT @count_det = 1


	 	SELECT @entry_detail_sequence =
			 substring (CONVERT (char(8),(@count_det +
			 10000000)),2,7) 

	 		

 	 	

		IF @addenda_flag = 1

		BEGIN

 SELECT @addenda_number = 0


		
		
			WHILE 1=1 
			BEGIN
			SET ROWCOUNT 1

			IF (@debug > 0)
			BEGIN
			SELECT "*** eft_ctx payment num ***" 
			SELECT @payment_num 
			END
 


			SELECT 
 	 	@sequence_id = sequence_id 
 	 	FROM eft_aptr
			WHERE payment_num = @payment_num 
			AND sequence_id > @last_sequence_id		 						 
			
			IF @@rowcount = 0 
			BREAK 
			SET ROWCOUNT 0

			SELECT @addenda_number	 =	 @addenda_number +1
			SELECT @addenda_sequence_number =
			 substring (CONVERT (char(5),(@addenda_number +
			 10000)),2,4) 
 
			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_ctx_sp - Determine the addenda_number"
			SELECT @addenda_number
			END

											 
			SELECT 
			
			@description = description 	+'$'+ convert(varchar(19),convert(money,(amt_net - amt_disc_taken ) ) )
			FROM eft_aptr
		 WHERE @payment_num = payment_num
		 	AND @sequence_id = sequence_id
			AND amt_net	<> 0


	 		
		 
			EXEC @result = eft_ctx2_sp
			@sequence						,
			@sequence_id						,
			@description						,
			@addenda_sequence_number			,
			@entry_detail_sequence	 	 					 

			SELECT @last_sequence_id = @sequence_id
				
			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_ctx - Call sp ctx2_sp "
			SELECT @sequence_id
			END

			IF 	(@addenda_number > 0)
			SELECT @addenda_record_indicator = '1'
 		
	

			END					


			END					


	
			
	
 		 
	EXEC @result = eft_ctx1_sp
	@sequence				 ,
	@transaction_code				,
	@vendor_aba_number			,
	@check_digit					,
	@vendor_bank_acct_num		,
	@payment_amount				,
	@vendor_code				,
	@addenda_sequence_number ,
	@vendor_name				,
	@addenda_record_indicator	,
	@bank_aba_number			,
	@entry_detail_sequence	,
	@file_fmt_code, 
	@individual_name 	 
			 
	
	
	SELECT @sequence_id = 0 
	
			IF (@debug > 0)
			BEGIN
			SELECT " *** eft_ctx - Call sp ctx1_sp "
			SELECT @addenda_sequence_number 
			END
 


GO
GRANT EXECUTE ON  [dbo].[eft_ctx_sp] TO [public]
GO
