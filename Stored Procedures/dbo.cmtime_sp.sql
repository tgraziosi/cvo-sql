SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\CM\PROCS\cmtime.SPv - e7.2.2 : 1.0
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[cmtime_sp]	@server_time int OUTPUT
AS 

DECLARE @hour int, @minute int, @second int,
	@time datetime

SELECT @time = getdate()

SELECT	@hour = datepart( hh, @time ),
	@minute = datepart( mi, @time ),
	@second = datepart( ss, @time )

IF (@hour > 12)
	SELECT	@hour = @hour - 12

SELECT @server_time = ( @hour * 3600 ) + ( @minute * 60 ) + @second

SELECT @server_time



/**/                                              
GO
GRANT EXECUTE ON  [dbo].[cmtime_sp] TO [public]
GO
