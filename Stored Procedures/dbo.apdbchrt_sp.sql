SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apdbchrt.SPv - e7.2.2 : 1.2
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROCEDURE [dbo].[apdbchrt_sp] 
 @account_code varchar(32),
 @active_date int,
 @inactive_date int,
 @inactive_flag int,
 @apply_date int,
 @result_flag smallint OUTPUT,
 @debug smallint
AS
DECLARE	
 @test varchar(80),
 @result smallint


SELECT
 @result=0

IF (@account_code = "NONE")

 SELECT 
 @result = 99,
 @result_flag = 4,
 @test = "The account_code is invalid."

ELSE IF (@inactive_flag = 1 AND @account_code != "NONE")
BEGIN

 IF ((@result != 99) AND
 (@inactive_flag = 1))
 SELECT
 @result = 99,
 @result_flag = 1,
 @test="The account is inactive."

 IF ((@result = 99) AND
 (@inactive_flag = 1) AND
 (@active_date !=0) AND
 (@inactive_date = 0))
 BEGIN
 IF (@apply_date < @active_date)
 SELECT
 @result = 99,
 @result_flag = 3,
 @test = "The account_code is inactive and invalid for this apply_date."
 END


 IF ((@result = 99) AND
 (@inactive_flag = 1) AND
 (@inactive_date != 0))
 BEGIN
 IF ( (@apply_date > @inactive_date) OR
 (@apply_date < @active_date))
 SELECT
 @result = 99,
 @result_flag = 3,
 @test = "The account is inactive, but, apply_date out of the active range."
 END
 
 END
 ELSE IF (@inactive_flag = 0 AND @account_code != "NONE")
 BEGIN

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
 @result_flag = 2,
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
 @result_flag = 2,
 @test = "The account is active, but, apply_date out of the active range."
 END

 END
 

IF (@debug = 1)
 SELECT
 @result_flag,
 @test
GO
GRANT EXECUTE ON  [dbo].[apdbchrt_sp] TO [public]
GO
