SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\arglvc.SPv - e7.2.2 : 1.6
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[arglvc_sp] 
 @sub_account_code varchar(32),
 @apply_date int,
 @return_one_value_flag smallint 
 
AS
DECLARE	
 @account_code varchar(32), 
 @active_date int, 
 @inactive_date int, 
 @inactive_flag int, 
 @done int, 
 @not_exist_flag smallint, 
 @not_active_flag smallint, 
 @not_valid_on_date_flag smallint, 
 @debug smallint, 
 @test varchar(80) 


SELECT
 @done = 0, 
 @account_code = "NONE",
 @debug = 0 

SELECT
 @not_exist_flag = 0,
 @not_active_flag = 0,
 @not_valid_on_date_flag = 0



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
BEGIN

 SELECT 
 @done = 1,
 @not_exist_flag = 1,
 @test = "The account_code does not exist in glchart."
 IF (@debug = 1)
 PRINT @test
END



IF ((@done != 1 ) AND
 (@inactive_flag = 1))
BEGIN
 SELECT
 @not_active_flag = 1,
 @test="The account is inactive."
 IF (@debug = 1)
 PRINT @test
END


IF ((@done != 1 ) AND
 (@active_date = 0) AND
 (@inactive_date = 0))
BEGIN
 SELECT
 @done = 1,
 @test = "The account_code is valid for date. active_date and inactive_date = 0" 
 IF (@debug = 1)
 PRINT @test
END


IF ((@done != 1 ) AND
 (@active_date !=0) AND
 (@inactive_date = 0))
 BEGIN
 IF (@apply_date >= @active_date)
 BEGIN
 SELECT
 @done = 1,
 @test = "The account_code is valid for date.  apply_date >= active_date, no inactive_date"
 IF (@debug = 1)
 PRINT @test
 END
 ELSE
 BEGIN
 SELECT
 @done = 1,
 @not_valid_on_date_flag = 1,
 @test = "The account_code is not valid for date. apply_date < active_date."
 IF (@debug = 1)
 PRINT @test
 END
 END

 
IF ((@done != 1) AND
 (@inactive_date != 0))
 BEGIN
 IF ( (@apply_date <= @inactive_date) AND
 (@apply_date >= @active_date))
 BEGIN
 SELECT
 @done = 1,
 @test = "The account is valid for date. apply_date is in the active range."
 IF (@debug = 1)
 PRINT @test
 END
 ELSE
 BEGIN
 SELECT
 @done = 1,
 @not_valid_on_date_flag = 1,
 @test = "The account is not valid for date. apply_date out of the active range."
 IF (@debug = 1)
 PRINT @test
 END
 END

IF ( @return_one_value_flag = 0 )
	SELECT
		@not_exist_flag,
		@not_active_flag,
		@not_valid_on_date_flag
ELSE
	RETURN @not_exist_flag + @not_active_flag +@not_valid_on_date_flag




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[arglvc_sp] TO [public]
GO
