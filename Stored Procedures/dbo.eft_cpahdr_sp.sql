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


















CREATE PROC [dbo].[eft_cpahdr_sp]
@sequence		   			 	smallint,
@client_num 	  				char(10), 
@file_creation_num				char(4),
@effective_date					int, 
@processing_centre		  		char(5),
@debug							smallint,
@curr_code						char(3)		
			  

AS  DECLARE 

@record_type_code 		    char(1),
@record_count				char(9),
@year						smallint,
@month						smallint,
@day						smallint,
@century					smallint,
@dayofyear					smallint,
@file_creation_date			char(6),
@reserved_blank				char(255),
@rec_length					int,
@cr_flag					smallint


	


	
	SELECT 
	@record_type_code 	= 'A',
	@record_count = '000000001',
	@reserved_blank = ' ',
	@cr_flag = 0,
	@rec_length = 58			



	



	EXEC appdtjul_sp 
	@year 	OUTPUT, 
	@month  OUTPUT , 
	@day  	OUTPUT,
    @effective_date

	SELECT @century = convert(smallint,substring(convert(char(4),@year),1,2)) - 20              
	SELECT @dayofyear = datepart(dy, (convert(varchar(2),@month) + '/' + 
									  convert(varchar(2),@day) 	+ '/' + 
									  convert(varchar(4),@year))
								)
	
	
    SELECT @file_creation_date = ( 
	    							 convert(char(1),@century)						+
								 substring(convert(char(4),@year),3,2)			+
								 substring(convert(char(4), 1000 + @dayofyear),2,3)
								 )
			

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
	  @record_type_code,
	  0,
	  @record_type_code	 				+
	  @record_count		 				+
	  @client_num						+
	  @file_creation_num				+
	  @file_creation_date				+
	  @processing_centre				+
	  substring(@reserved_blank,1,20)   +		
	  @curr_code,					
	  @cr_flag,
	  @rec_length
	)

	


	
	SELECT @sequence 	=  	@sequence + 1,
	   	   @rec_length 	= 	255


	WHILE 1=1		
	BEGIN
		IF @sequence = 7
		BREAK

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
	  	@record_type_code,
	  	0,
		substring(@reserved_blank,1,255),
		@cr_flag,
		@rec_length
		)


		IF (@debug > 0)
		BEGIN
			SELECT " *** eft_cpah_sp - fill blank at end of header loop (6 ROWS)"
			SELECT @sequence
		END


		SELECT @sequence =  @sequence + 1
	END


	SELECT @rec_length 	= 	131,		
		   @cr_flag		= 	1

	INSERT eft_temp			
  
	( sequence,		
   	record_type_code,
   	addenda_count,
   	eft_data,
   	cr_flag,
   	rec_length  )

	VALUES

	( @sequence,
  	@record_type_code,
  	0,
	substring(@reserved_blank,1,131),		
	@cr_flag,
	@rec_length)


	IF (@debug > 0)
	BEGIN
		SELECT " *** eft_cpah_sp - fill blank at end of header after loop with CR (7th row)"
		SELECT @sequence 
	END


	 
GO
GRANT EXECUTE ON  [dbo].[eft_cpahdr_sp] TO [public]
GO
