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














CREATE PROC [dbo].[eft_CPADtl_sp]
@sequence						smallint,
@client_name					char(30), 
@vendor_aba_number 				char(9),
@vendor_account_num 		    char(12), 
@payment_amount          		char(10), 
@vendor_code				    char(12),
@vendor_name					char(30),
@payment_num					char(16),
@description					char(15),
@segment						smallint,
@client_num 	  				char(10),
@file_creation_num				char(4),
@date_doc			 	 		int,
@transaction_code				char(3),	
@debug							smallint
		
   
AS  DECLARE 
@record_type_code				char(1),
@entry_detail_sequence	 		char(9),

@client_short_name				char(15),
@reserved_num					char(22),
@reserved_blank					char(22),
@reserved_last					char(11),
@count_det						smallint,
@year							smallint,
@month							smallint,
@day							smallint,
@dayofyear						smallint,
@payment_date					char(6),
@detail_header_flag				smallint,
@customer_num					char(19),
@rec_length						int,
@cr_flag						smallint


		


		
		SELECT
		@record_type_code = 'C',
		@client_short_name = ' ',
		@reserved_num 	= '0000000000000000000000',
		@reserved_blank = ' ',
		@reserved_last = ' ',
		@detail_header_flag = 0,
		@customer_num = ltrim(@vendor_code),
		@cr_flag = 0,
		@rec_length = 255

		SELECT @client_short_name = short_name FROM apmaster		
		WHERE vendor_code = @customer_num

		



		EXEC appdtjul_sp 
		@year 	OUTPUT, 
		@month  OUTPUT , 
 		@day  	OUTPUT,
 	    @date_doc

		SELECT @dayofyear = datepart(dy, (convert(varchar(2),@month) + '/' + 
										  convert(varchar(2),@day) 	+ '/' + 
										  convert(varchar(4),@year))
									)
		
		
 	    SELECT @payment_date = ( 
 	    					   '0' +
							   substring(convert(char(4),@year),3,2)			+
							   substring(convert(char(4), 1000 + @dayofyear),2,3)
							   )

	 	





		SELECT @count_det = count(1) + 2  		
		FROM eft_temp
	   	WHERE  record_type_code = 'C'
		AND    addenda_count = 1	

	 	SELECT @entry_detail_sequence =
			       substring (CONVERT (char(10),(@count_det + 1000000000)),2,9)  

	 		

  	 	





		IF @segment = 1

		BEGIN

			SELECT @detail_header_flag = 1,
				   @rec_length = 253


			


			
		  		 
			INSERT eft_temp

			( sequence  ,	
			  record_type_code ,
			  addenda_count,
		  	  eft_data,
		  	  cr_flag,
		  	  rec_length  )

			VALUES

			( @sequence,
			  @record_type_code ,
			  @detail_header_flag,
			  @record_type_code 				+ 		
			  @entry_detail_sequence 			+ 		
			  @client_num 						+ 		
			  @file_creation_num				+		
			  @transaction_code					+		
			  @payment_amount               	+		
			  @payment_date						+		
			  @vendor_aba_number 				+		
			  @vendor_account_num 				+		
			  substring(@reserved_num,1,22)		+		
			  substring(@reserved_num,1,3)		+		
			  @client_short_name		    	+		
			  @vendor_name						+		
			  @client_name						+		
			  @client_num						+		
			  @customer_num						+		
			  substring(@reserved_num,1,9)		+		
			  substring(@reserved_blank,1,12)	+		
			  @description	    				+		
			  substring(@reserved_blank,1,22)	+		
			  substring(@reserved_blank,1,2),			
			  @cr_flag,
			  @rec_length )
					 

					IF (@debug > 0)
					BEGIN
					SELECT " *** eft_CPADtl_sp - Created Detail Record (seg1)"
					SELECT @sequence, @segment
					END

		END

		



		
		IF @segment = 2
		BEGIN

			SELECT @rec_length = 251
			


			
		  		 
			INSERT eft_temp

			( sequence  ,	
			  record_type_code ,
			  addenda_count,
		  	  eft_data,
		  	  cr_flag,
		  	  rec_length  )

			VALUES

			( @sequence,
			  @record_type_code ,
			  @detail_header_flag,
			  @reserved_last					+		
			  @transaction_code					+		
			  @payment_amount               	+		
			  @payment_date						+		
			  @vendor_aba_number 				+		
			  @vendor_account_num 				+		
			  substring(@reserved_num,1,22)		+		
			  substring(@reserved_num,1,3)		+		
			  @client_short_name		    	+		
			  @vendor_name						+		
			  @client_name						+		
			  @client_num						+		
			  @customer_num						+		
			  substring(@reserved_num,1,9)		+		
			  substring(@reserved_blank,1,12)	+		
			  @description	    				+		
			  substring(@reserved_blank,1,22)	+		
			  substring(@reserved_blank,1,2)	+		
			  @reserved_last,							
			  @cr_flag,
			  @rec_length )
					 

					IF (@debug > 0)
					BEGIN
					SELECT " *** eft_CPADtl_sp - Created Detail Record (seg2)"
					SELECT @sequence, @segment
					END
		END


		


		
		IF @segment > 2
		BEGIN

				SELECT @rec_length = 240

			



				IF @segment = 6
				SELECT @cr_flag = 1

				


				
			  		 
				INSERT eft_temp

				( sequence  ,	
				  record_type_code ,
				  addenda_count,
			  	  eft_data,
			  	  cr_flag,
			  	  rec_length  )

				VALUES

				( @sequence,
				  @record_type_code ,
				  @detail_header_flag,
				  @transaction_code					+		
				  @payment_amount               	+		
				  @payment_date						+		
				  @vendor_aba_number 				+		
				  @vendor_account_num 				+		
				  substring(@reserved_num,1,22)		+		
				  substring(@reserved_num,1,3)		+		
				  @client_short_name		    	+		
				  @vendor_name						+		
				  @client_name						+		
				  @client_num						+		
				  @customer_num						+		
				  substring(@reserved_num,1,9)		+		
				  substring(@reserved_blank,1,12)	+		
				  @description	    				+		
				  substring(@reserved_blank,1,22)	+		
				  substring(@reserved_blank,1,2)	+		
				  @reserved_last,							
				  @cr_flag,
				  @rec_length )
						 

						IF (@debug > 0)
						BEGIN
						SELECT " *** eft_CPADtl_sp - Created Detail Record "
						SELECT @sequence, @segment
						END
  		END
		

GO
GRANT EXECUTE ON  [dbo].[eft_CPADtl_sp] TO [public]
GO
