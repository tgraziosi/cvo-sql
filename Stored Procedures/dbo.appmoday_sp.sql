SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appmoday.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[appmoday_sp]	@month		smallint,
				@year		smallint,
				@max_day	smallint OUTPUT
AS

DECLARE	@leap	tinyint


IF @year % 4 = 0 AND @year % 100 != 0 OR @year % 400 = 0
	SELECT @leap = 1
ELSE
	SELECT @leap = 0


IF ( @month = 4 OR @month = 6 OR @month = 9 OR @month = 11 )
	SELECT	@max_day = 30

ELSE IF ( @month = 2 )
BEGIN
	IF @leap = 1
		SELECT	@max_day = 29
	ELSE
		SELECT	@max_day = 28
END

ELSE
	SELECT	@max_day = 31


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appmoday_sp] TO [public]
GO
