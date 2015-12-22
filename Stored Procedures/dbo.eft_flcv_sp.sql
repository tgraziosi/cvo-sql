SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_flcv.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[eft_flcv_sp]
@amount 	 		float,
@amount_char		char(15) OUTPUT

 
AS 

DECLARE

		@dec char(2),
 @integer char(12),
 @lenght int

SELECT @amount_char = str(@amount,15,2) 

SELECT @dec = substring(@amount_char,14,2)

SELECT @integer = ltrim(substring(@amount_char,1,12) )

SELECT @lenght = datalength(rtrim(@integer))

SELECT @amount_char = replicate ('0', (13-@lenght) ) + 
					 rtrim(@integer) + @dec 

 
GO
GRANT EXECUTE ON  [dbo].[eft_flcv_sp] TO [public]
GO
