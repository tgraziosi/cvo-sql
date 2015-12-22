SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_chdr.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROC [dbo].[eft_chdr_sp]
@sequence				 	smallint,
@file_fmt_code				varchar(8), 
@eft_company_name	 	varchar(40),
@cash_aba_number		 	varchar(16),
@company_entry_description	char(10),
@descriptive_date 			int,
@effective_date 			int,
@originator_status_code		char(1),
@company_identification		char(10),
@company_data				char(20)

AS DECLARE 

@addenda_type_code 		 	char(2),
@record_type_code 		 	char(1),
@service_class_code			char(3),
@company_name				char(16),

@standard_entry_class		char(3)	,
@company_descriptive_date	char(6),
@effective_entry_date		char(6),
@settlement_date			char(3),
@originator_dfi				char(8),
@batch_number				char(7),
@year						smallint,
@month						smallint,
@day						smallint,
@rec_length					int,
@cr_flag					smallint





		
		
		SELECT 
		@addenda_type_code			= '00' ,
	 	@record_type_code 			= '5',
		@service_class_code			= '200',	 		
		@company_name 	 		 	= substring(@eft_company_name,1,16) ,
		@settlement_date	 		= ' ' ,
	 
		@standard_entry_class	 	= substring(@file_fmt_code,1,3) 	,
	 	@originator_dfi			 	= substring(@cash_aba_number,1,8) ,
		@batch_number				= '0000001',
		@cr_flag 					= 1,
		@rec_length					= 94


		
		
		EXEC appdtjul_sp 
		@year 	OUTPUT, 
		@month OUTPUT , 
 		@day 	OUTPUT,
 	 @descriptive_date
		
 	 SELECT @company_descriptive_date = 
 	 	 substring(convert(char(4),@year),3,2) +
		 convert(char(2),substring(str(100+@month,3),2,2)) +
		 convert(char(2),substring(str(100+@day,3),2,2)) 
			 	 
			 
		
		
		EXEC appdtjul_sp 
		@year 	OUTPUT, 
		@month OUTPUT , 
 		@day 	OUTPUT,
 	 @effective_date
		
 	 SELECT @effective_entry_date =
 	 	 substring(convert(char(4),@year),3,2) +
		 convert(char(2),substring(str(100+@month,3),2,2)) +
		 convert(char(2),substring(str(100+@day,3),2,2)) 
			 
			 

	INSERT eft_temp

	(sequence ,		
	 record_type_code ,
	 addenda_count,
	 eft_data,
	 cr_flag,
	 rec_length )

	VALUES

	( @sequence,			 
	 @record_type_code ,
	 0,
	 @record_type_code +
	 @service_class_code			+
	 @company_name 	 		 +
	 @company_data					+
	 @company_identification	 	+
	 @standard_entry_class	 		+ 
	 @company_entry_description +
	 @company_descriptive_date +
	 @effective_entry_date +
 	 @settlement_date	 			+
	 @originator_status_code		+			
 	 @originator_dfi		 		+
 	 @batch_number,
 	 @cr_flag,
 	 @rec_length)
	 	


	 
GO
GRANT EXECUTE ON  [dbo].[eft_chdr_sp] TO [public]
GO
