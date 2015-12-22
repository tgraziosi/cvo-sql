SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_fctr.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[eft_fctr_sp]
@sequence					smallint,
@addenda_count				char(6),
@entry_hash					char(10),
@total_credit				char(12)


AS DECLARE 
@addenda_type_code 		 	char(2),
@record_type_code 		 	char(1),
@batch_count				char(6)	,
@block_count				char(6)	 ,
@total_debit				char(12),
@reserved					char(39),
@rec_length					int,
@cr_flag					smallint


 
 		
		
		SELECT 
		@addenda_type_code			= '00' ,
 		@record_type_code 			= '9',
	 	@total_debit				= '000000000000' ,
		@reserved					= ' ',
		@batch_count				= '000001'	,
		@block_count				= '000001',
		@cr_flag = 1,
		@rec_length = 94


		 	 		
					 

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
	 @record_type_code +
	 @batch_count +
	 @block_count +
	 '00' + 
	 @addenda_count				+
	 @entry_hash +
	 @total_debit					+
	 @total_credit					+			 	
	 @reserved,
	 @cr_flag,
	 @rec_length
	 )
	 
GO
GRANT EXECUTE ON  [dbo].[eft_fctr_sp] TO [public]
GO
