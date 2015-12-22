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














CREATE PROC [dbo].[eft_cpad2_sp]
@sequence						smallint,
@segment						smallint,
@debug							smallint
		
   
AS  DECLARE 
@record_type_code				char(1),
@reserved_num					char(25),
@reserved_blank					char(255),
@cr_flag						smallint,
@rec_length						int


		


		
		SELECT
		@record_type_code = 'C',
		@reserved_num 	= '0000000000000000000000000',
		@reserved_blank = ' ',
		@cr_flag = 0,
		@rec_length = 255



	



		



		
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
			  2,
			  
			  -- Mod100 Start
			  substring(@reserved_blank,1,14)	+
			  substring(@reserved_num,1,25)		+
			  substring(@reserved_blank,1,12)	+
			  substring(@reserved_num,1,25)		+
			  substring(@reserved_blank,1,104)	+
			  substring(@reserved_num,1,9)		+
			  substring(@reserved_blank,1,62),









			  -- Mod100 End

			  @cr_flag,
			  @rec_length )
						 

					IF (@debug > 0)
					BEGIN
					SELECT ' *** eftcapd2_sp - Created Blank Detail Record (Seg2)'
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
			  2,
			  -- Mod100 Start
			  substring(@reserved_blank,1,3)	+
			  substring(@reserved_num,1,25)		+
			  substring(@reserved_blank,1,12)	+
			  substring(@reserved_num,1,25)		+
			  substring(@reserved_blank,1,104)	+
			  substring(@reserved_num,1,9)		+
			  substring(@reserved_blank,1,62),









			  -- Mod100 End

			  @cr_flag,
			  @rec_length )
						 

					IF (@debug > 0)
					BEGIN
					SELECT ' *** eftcapd2_sp - Created Blank Detail Record '
					SELECT @sequence, @segment
					END
  		END


  	


GO
GRANT EXECUTE ON  [dbo].[eft_cpad2_sp] TO [public]
GO
