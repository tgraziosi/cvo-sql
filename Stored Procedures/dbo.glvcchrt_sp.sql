SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glvcchrt.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[glvcchrt_sp] 
 @sub_account_code	varchar(32),
 @apply_date		int,
 @result_flag		smallint = -1	OUTPUT,
 @debug			smallint = 0
AS
DECLARE	
 @account_code varchar(32),
 @test varchar(80),
 @active_date int,
 @inactive_date int,
 @inactive_flag int,
 @result smallint,
	@form_call		smallint


SELECT
 @result=0,
 @account_code = "NONE"

IF	@result_flag = -1
	SELECT	@form_call = 1
ELSE	
	SELECT	@form_call = 0


SELECT
 @account_code = account_code,
 @active_date = active_date,
 @inactive_date = inactive_date,
 @inactive_flag = inactive_flag
FROM
 glchart
WHERE
 account_code = @sub_account_code

IF (@account_code = "NONE")

 SELECT 
 @result = 99,
 @result_flag = 1,
 @test = "The account_code is invalid."


IF ((@result != 99) AND
 (@inactive_flag = 1))
 SELECT
 @result = 99,
 @result_flag = 1,
 @test="The account is inactive."


IF ((@result != 99) AND
 (@active_date = 0) AND
 (@inactive_date = 0))
 SELECT
 @result = 99,
 @result_flag = 0,
 @test = "The account_code is active. active_date and inactive_date = 0" 
ELSE IF ((@result != 99) AND
 (@active_date !=0) AND
 (@inactive_date = 0))
 BEGIN
 IF (@apply_date >= @active_date)
 SELECT
 @result = 99,
 @result_flag = 0,
 @test = "The account_code is active.  apply_date >= active_date, no inactive_date"
 ELSE
 SELECT
 @result = 99,
 @result_flag = 1,
 @test = "The account_code is active but apply_date < active_date."
 END
 

IF ((@result != 99) AND
 (@inactive_date != 0))
 BEGIN
 IF ( (@apply_date <= @inactive_date) AND
 (@apply_date >= @active_date))
 SELECT
 @result = 99,
 @result_flag = 0,
 @test = "The account is active. apply_date is in the active range."
 ELSE
 SELECT
 @result = 99,
 @result_flag = 1,
 @test = "The account is active, but, apply_date out of the active range."
 END


IF (@debug = 1)
 SELECT
 @result_flag,
 @test


IF (@form_call = 1 )
 SELECT
 @result_flag





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glvcchrt_sp] TO [public]
GO
