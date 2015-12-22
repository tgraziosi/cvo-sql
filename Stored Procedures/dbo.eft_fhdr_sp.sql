SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_fhdr.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                






CREATE PROC [dbo].[eft_fhdr_sp]
@sequence		 			 	smallint ,
@aba_number 	 				varchar(20),
@bank_name						char(40),
@immediate_origin 				char (10)	 	 ,
@immediate_origin_name 		char(23)  ,
@file_id						varchar(1)	 

AS DECLARE 

@record_type_code 		 char(1),
@addenda_type_code 		 	char(2),
@date						char(6)	,
@time_work					char(8) ,
@time						char(4) ,
@record_size				char(3),
@blocking_factor			char(2),
@format_code				char(1),
@reference_code 			char(8),
@priority_code				char(2) ,
@immediate_destination		char(10),	
@immediate_destination_name char(23),
@rec_length					int,
@cr_flag					smallint






		
		
		SELECT 
		@addenda_type_code	= '00' ,
		@record_type_code 	= '1',
		@priority_code		= '01',	 		
	 @file_id 			= 'A' ,
		@record_size		= '094'	,
		@blocking_factor = '10',
		@format_code = '1' ,
		@reference_code		= '',
		@cr_flag = 1,
		@rec_length = 94

			 		

		

	 SELECT @date = convert(varchar(6), getdate(),12)


		

	 SELECT @time_work = convert(varchar(8), getdate(),8)

		SELECT @time = substring(@time_work,1,2) 
		 + substring(@time_work,4,2)


		SELECT 	
		@immediate_destination 	 =	' ' +substring(@aba_number,1,9) , 
		@immediate_destination_name= ltrim(substring(@bank_name,1,23) ) 
						
			
	INSERT eft_temp
	 
	 ( sequence ,		
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
	 @record_type_code	 				+
	 @priority_code	 				+
	 @immediate_destination			+
	 @immediate_origin					+
	 @date								+
	 @time								+ 
 	 @file_id 							+			
 	 @record_size						+
 	 @blocking_factor 					+
	 @format_code 					+
 @immediate_destination_name 		+
	 @immediate_origin_name 			+
	 @reference_code,
	 @cr_flag,
	 @rec_length
	)
	 	


	 
GO
GRANT EXECUTE ON  [dbo].[eft_fhdr_sp] TO [public]
GO
