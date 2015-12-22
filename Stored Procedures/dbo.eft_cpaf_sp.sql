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















CREATE PROC [dbo].[eft_cpaf_sp]
@sequence					smallint,
@client_num					char(10),
@file_creation_num			char(4),
@total_credit				char(14)


AS  DECLARE 
@record_type_code 		 	char(1),
@record_count				char(9),
@total_count				char(9),	
@reserved_num				char(50),	
@reserved_blank				char(255),
@loop_count					smallint,
@cr_flag					smallint,
@rec_length					int

  
  		


		
		SELECT 
   		@record_type_code 			= 'Z',
		@record_count				= '000000001',
		@reserved_num				= '00000000000000000000000000000000000000000000000000',  
		@reserved_blank				= ' ',
		@loop_count					= 1,
		@cr_flag 					= 0,
		@rec_length 				= 255


	





	SELECT @total_count = substring(convert(char(10),count(1) + 1000000000),2,9)      
	FROM eft_temp
	WHERE record_type_code = 'C'
	AND addenda_count < 2

	SELECT @record_count = substring(@record_count,1,8) + convert(char(9), @total_count + 2)  


	INSERT eft_temp

	( sequence,		
	  record_type_code,
	  addenda_count,
   	  eft_data,
   	  cr_flag,
	  rec_length
	)

	VALUES

	( @sequence,			
	  @record_type_code ,
	  0,
	  @record_type_code             +
	  @record_count					+
	  @client_num	                +
	  @file_creation_num			+
	  substring(@reserved_num,1,14) +			
	  substring(@reserved_num,1,8)	+			
	  @total_credit					+		
	  substring(@total_count,2,8)					+
	  @reserved_num     +				
	  @reserved_num		+			
	  @reserved_num		+			
	  substring(@reserved_num,1,37),		
	  @cr_flag,
	  @rec_length
	)
	 

	




	WHILE @loop_count < 5	
	BEGIN

		SELECT @sequence = @sequence + 1

		INSERT eft_temp

		( sequence  ,		
		  record_type_code ,
	 	  addenda_count,
   	 	  eft_data,
	   	  cr_flag,
		  rec_length
   	 	)

		VALUES

		( @sequence,
		  @record_type_code,
		  0,
		  @reserved_num    +				
		  @reserved_num    +				
		  @reserved_num    +				
		  @reserved_num    +				
		  @reserved_num    +				
		  substring(@reserved_num,1,5),			
		  @cr_flag,
		  @rec_length
		)
		
		SELECT @loop_count = @loop_count + 1		  	 		

	END

	SELECT @sequence 	= @sequence + 1,
		   @cr_flag 	= 1,
		   @rec_length 	= 189

	INSERT eft_temp			

	( sequence  ,		
	  record_type_code ,
 	  addenda_count,
	  eft_data,
   	  cr_flag,
	  rec_length
 	)

	VALUES

	( @sequence,			
	  @record_type_code ,
	  0,
	  @reserved_num    +			
	  @reserved_num    +			
	  @reserved_num    +			
	  substring(@reserved_num,1,39),	
	  @cr_flag,
	  @rec_length
	)

GO
GRANT EXECUTE ON  [dbo].[eft_cpaf_sp] TO [public]
GO
