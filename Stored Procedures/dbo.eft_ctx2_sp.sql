SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_ctx2.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[eft_ctx2_sp]
@sequence							smallint,
@sequence_id						int,
@description						char(80),
@addenda_sequence_number			char(4),
@entry_detail_sequence				char(7)




AS DECLARE 
@record_type_code					char(1),
@addenda_type_code 				 	char(2),
@payment_related_information		char(80) ,
@char_20							char(20),
@rec_length							int,
@cr_flag							smallint






		
		
	 SELECT 
	 @record_type_code		='7',
	 @addenda_type_code			= '05' ,
	 @payment_related_information = @description,
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
	 @sequence_id ,			
	 @record_type_code 			+
	 @addenda_type_code			+
	 @payment_related_information +
	 @addenda_sequence_number	 +
	 @entry_detail_sequence,
	 @cr_flag,
	 @rec_length
	)

	 
GO
GRANT EXECUTE ON  [dbo].[eft_ctx2_sp] TO [public]
GO
