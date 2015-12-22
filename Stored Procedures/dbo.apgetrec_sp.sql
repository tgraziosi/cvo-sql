SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\apgetrec.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                




CREATE PROC [dbo].[apgetrec_sp]	@cycle_code	char(8),
				@cur_date	int,
				@rec_date	int OUTPUT
AS

DECLARE	@cycle_type	smallint,
	@number		smallint,
	@result		smallint,
	@month		smallint,
	@day		smallint,
	@year		smallint,
	@juldate	int

SELECT	@cycle_type = cycle_type,
	@number = number
FROM	apcycle
WHERE	cycle_code = @cycle_code

SELECT	@juldate = @cur_date


IF ( @cycle_type = 1 )
	SELECT @rec_date = @cur_date + 1


ELSE IF ( @cycle_type = 2 )
	SELECT @rec_date = @cur_date + 7


ELSE IF ( @cycle_type = 3 )
BEGIN
	EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @juldate

	IF ( @day < 15 )
		SELECT	@day = 15
	ELSE	
	BEGIN
		SELECT	@day = 1

		IF ( @month = 12 )
		BEGIN
			SELECT	@month = 1
			SELECT @year = @year + 1
		END
		ELSE
			SELECT	@month = @month + 1
	END

	EXEC appjuldt_sp @year, @month, @day, @juldate OUTPUT

	SELECT @rec_date = @juldate
END


ELSE IF ( @cycle_type = 4 )
BEGIN
	EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @juldate

	IF ( @month = 12 )
	BEGIN
		SELECT	@month = 1
		SELECT @year = @year + 1
	END
	ELSE
		SELECT	@month = @month + 1

	SELECT @result = 0

	WHILE ( @result = 0 )
	BEGIN
		EXEC @result = appjuldt_sp @year, @month, @day, @juldate OUTPUT
		SELECT	@day = @day - 1
	END

	SELECT @rec_date = @juldate
END


ELSE IF ( @cycle_type = 5 )
	SELECT @rec_date = @cur_date + @number


ELSE IF ( @cycle_type = 6 )
	SELECT @rec_date = @cur_date + (@number * 7)


ELSE IF ( @cycle_type = 7 )
BEGIN
	EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @juldate

	SELECT	@month = @month + @number
	IF ( @month > 12 )
	BEGIN
		SELECT	@month = @month - 12
		SELECT @year = @year + 1
	END

	SELECT @result = 0

	WHILE ( @result = 0 )
	BEGIN
		EXEC @result = appjuldt_sp @year, @month, @day, @juldate OUTPUT
		SELECT	@day = @day - 1
	END

	SELECT @rec_date = @juldate
END


GO
GRANT EXECUTE ON  [dbo].[apgetrec_sp] TO [public]
GO
