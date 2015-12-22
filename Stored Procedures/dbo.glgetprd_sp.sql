SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/* PVCS Revision or Version:Revision              
I:\vcs\GL\PROCS\glgetprd.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[glgetprd_sp] @period_end int, @number smallint, @end int OUTPUT
AS

DECLARE		@start int, @count smallint

SELECT	@end = @period_end, @count = ABS(@number)

IF @number > 0
BEGIN
	WHILE ( @count > 0 )
	BEGIN
		SELECT @end = min(period_end_date)
		FROM glprd 
		WHERE period_end_date > @end

		
		IF @end IS NULL
			BREAK

		SELECT @count = @count - 1
	END
END
ELSE
BEGIN
	WHILE ( @count > 0 )
	BEGIN
		SELECT @end = max(period_end_date)
		FROM glprd 
		WHERE period_end_date < @end

		
		IF @end IS NULL
			BREAK

		SELECT @count = @count - 1
	END
END

SET ROWCOUNT 0

IF @count != 0 OR @end IS NULL
	SELECT @end = 0


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[glgetprd_sp] TO [public]
GO
