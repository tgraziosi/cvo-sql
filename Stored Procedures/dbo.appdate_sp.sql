SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appdate.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[appdate_sp]	@jul_date int OUTPUT,
				@return_row smallint = 0
AS 

DECLARE @status int, @year int, @month int, @day int,
	@time datetime

SELECT @time = getdate()

SELECT	@year = datepart( yy, @time ),
	@month = datepart( mm, @time ),
	@day = datepart( dd, @time )

EXEC @status = appjuldt_sp @year, @month, @day, @jul_date OUTPUT

IF ( @return_row = 1 )
	SELECT @jul_date

RETURN @status


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appdate_sp] TO [public]
GO
