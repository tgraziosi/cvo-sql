SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_cctr.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[eft_cctr_sp]
@sequence					smallint,
@addenda_count				char(6),
@tax_id				 	varchar(10)	, 
@cash_aba_number			varchar(16),
@entry_hash					char(10),
@total_credit				char(12)


AS DECLARE 

@addenda_type_code 		 	char(2),
@record_type_code 		 	char(1),
@service_class_code			char(3)	 ,
@total_debit				char(12),
@company_identification		char(10),
@message					char(19) ,
@reserved					char(6),
@originating_identification	char(8),
@batch_number				char(7),
@rec_length					int,
@cr_flag					smallint


 
 		
		
		SELECT 
		@addenda_type_code			= '00' ,
	 	@record_type_code 			= '8',
		@service_class_code			= '200',
		@total_debit				= '000000000000' ,
		@company_identification = substring(@tax_id,1,10),
		@message					= ' ',
		@reserved					= ' ',
		@originating_identification = substring(@cash_aba_number,1,10) ,
		@batch_number				= '0000001',
		@cr_flag = 1,
		@rec_length = 94

		 	 		
					 

	INSERT eft_temp

	(	sequence ,			
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
	 @record_type_code +
	 @service_class_code			+
	 @addenda_count +
	 @entry_hash +
	 @total_debit					+
	 @total_credit					+			 	
	 @company_identification 	+
	 @message						+
	 @reserved						+
	 @originating_identification	+
	 @batch_number,
	 @cr_flag,
	 @rec_length
	 	 
	 )
	 
GO
GRANT EXECUTE ON  [dbo].[eft_cctr_sp] TO [public]
GO
