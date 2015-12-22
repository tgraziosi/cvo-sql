SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appjuldt.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[appjuldt_sp]	@year int, @month int, @date int,
				@jul_date int OUTPUT
AS 

DECLARE @false int, @true int, @leap smallint

SELECT @false = 0, @true = 1, @jul_date = 0

IF @year %4 = 0 AND @year %100 != 0 OR @year %400 = 0
	SELECT @leap = 1
ELSE
	SELECT @leap = 0

IF @year <= 0 OR @month NOT BETWEEN 1 AND 12 
 OR @date < 1
 OR ( @month IN ( 1, 3, 5, 7, 8, 10, 12 ) AND @date > 31 )
 OR ( @month IN ( 4, 6, 9, 11 ) AND @date > 30 )
 OR ( @month = 2 AND @leap = 1 AND @date > 29 )
 OR ( @month = 2 AND @leap = 0 AND @date > 28 )
	RETURN @false


SELECT @year = @year - 1
SELECT @jul_date = @year * 365 + @year/4 - @year/100 + @year/400
SELECT @month = @month - 1
SELECT @year = @year + 1


WHILE ( @month > 0 )
BEGIN
	IF @month IN ( 1, 3, 5, 7, 8, 10, 12 )
		SELECT @jul_date = @jul_date + 31
	ELSE
	IF @month IN ( 4, 6, 9, 11 )
		SELECT @jul_date = @jul_date + 30
	ELSE
	IF @month = 2
	BEGIN
		IF @leap = 1
			SELECT @jul_date = @jul_date + 29
		ELSE
			SELECT @jul_date = @jul_date + 28
	END
	ELSE
	BEGIN
		SELECT @jul_date = 0
		RETURN @false
	END

	SELECT @month = @month - 1

END

SELECT @jul_date = @jul_date + @date

RETURN @true 


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appjuldt_sp] TO [public]
GO
