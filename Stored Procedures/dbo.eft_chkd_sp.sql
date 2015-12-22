SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\eft_chkd.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[eft_chkd_sp]
@aba_number 	varchar(16),
@check_digit char(1)		 OUTPUT	

 
AS DECLARE 

@receiving_dfi	 				char(8)	,
@weight_1							smallint	,
@weight_3							smallint	,
@weight_7							smallint	,
@position							smallint ,
@number								smallint,
@sum								float,	
@multiple							float					


		
		
		SELECT 	 
		@receiving_dfi				 =substring(@aba_number,1,8) ,
		@weight_1					 = 1,	
		@weight_3					 = 3,	
		@weight_7					 = 7 ,
		@position					 = 0,
		@number						 = 0,
		@sum						 = 0	 			 		




WHILE 1=1 
BEGIN
SET ROWCOUNT 1

SELECT @position = @position + 1

IF @position > 8
BREAK

SELECT @number = convert (smallint, substring(@receiving_dfi,@position,1))


			

IF @position IN (3,6)
SELECT @number = @number * @weight_1

IF @position IN (1,4,7)
SELECT @number = @number * @weight_3

IF @position IN (2,5,8)
SELECT @number = @number * @weight_7


SELECT @sum = @sum + @number


END

SELECT @multiple = ceiling (@sum/10) * 10

			


SELECT @check_digit = convert(char(1),(@multiple - @sum) )

	 
GO
GRANT EXECUTE ON  [dbo].[eft_chkd_sp] TO [public]
GO
