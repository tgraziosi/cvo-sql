SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\APPCORE\PROCS\appdtjul.SPv - e7.2.2 : 1.1
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                


CREATE PROC	[dbo].[appdtjul_sp]	@year int OUTPUT, @month int OUTPUT , 
				@date int OUTPUT, @jul_date int
AS 

DECLARE @false smallint, @true smallint, @leap smallint, @first_day int

SELECT 	@false = 0,
	@true = 1	


SELECT @year = ( @jul_date / 365 ) + 1


SELECT	@first_day = @jul_date + 1


WHILE ( @first_day > @jul_date )
BEGIN

	EXEC appjuldt_sp @year, 1, 1, @first_day OUTPUT

	IF ( @jul_date < @first_day )
		SELECT @year = @year - 1

	ELSE IF ( @jul_date = @first_day )
	BEGIN
		SELECT @date = 1
		SELECT @month = 1
		RETURN
	END			
END


IF @year % 4 = 0 AND @year % 100 != 0 OR @year % 400 = 0
	SELECT @leap = 1
ELSE
	SELECT @leap = 0


SELECT	@date = @jul_date - @first_day + 1
SELECT	@month = 0


WHILE ( @month <= 12 AND @date > 0 )
BEGIN
	SELECT @month = @month + 1

	IF ( @month = 1 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 2 )
		IF ( @date <= 28 AND @leap = 0 ) OR
	 	 ( @date <= 29 AND @leap = 1 )
			BREAK

		ELSE IF @leap = 0
		BEGIN			
			SELECT @date = @date - 28
		 	CONTINUE
		END

		ELSE IF @leap = 1
		BEGIN			
			SELECT @date = @date - 29
		 	CONTINUE
		END


	IF ( @month = 3 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 4 )
		IF ( @date <= 30 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 30
		 	CONTINUE
		END

	IF ( @month = 5 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 6 )
		IF ( @date <= 30 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 30
		 	CONTINUE
		END

	IF ( @month = 7 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 8 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 9 )
		IF ( @date <= 30 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 30
		 	CONTINUE
		END

	IF ( @month = 10 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END

	IF ( @month = 11 )
		IF ( @date <= 30 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 30
		 	CONTINUE
		END

	IF ( @month = 12 )
		IF ( @date <= 31 )
			BREAK
		ELSE
		BEGIN			
			SELECT	@date = @date - 31
		 	CONTINUE
		END
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appdtjul_sp] TO [public]
GO
