SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\apptime.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[apptime_sp]	@jul_time int OUTPUT
AS 

DECLARE @hour int, @minute int, @second int, @time datetime

SELECT @time = getdate()

SELECT	@hour = datepart( hh, @time ),
	@minute = datepart( mi, @time ),
	@second = datepart( ss, @time )

SELECT @jul_time = @hour * 3600 + @minute * 60 + @second

RETURN 



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[apptime_sp] TO [public]
GO
