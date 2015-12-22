SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AP\PROCS\appdtdsc.SPv - e7.2.2 : 1.4
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                





CREATE PROC	[dbo].[appdtdsc_sp]	@module_id	int,
				@terms_code	char(8),
				@date_doc	int,
				@date_discount	int OUTPUT,
				@app_error_flag	smallint OUTPUT
AS
DECLARE @discount_days smallint,
	@terms_type smallint,
	@min_days_due smallint,
	@date_disc int,
	@year	 smallint,
	@month	 smallint,
	@day	 smallint
	
SELECT @app_error_flag = 0


IF ( @module_id = 4000 )
BEGIN
	SELECT @discount_days = discount_days,
	 @terms_type = terms_type,
	 @date_disc = date_discount,
	 @min_days_due = min_days_due
	FROM apterms
	WHERE terms_code = @terms_code

	IF ( @@ROWCOUNT = 0 )
	BEGIN
		SELECT @app_error_flag = -500
		RETURN
	END
END
ELSE 	
BEGIN
	SELECT @app_error_flag = -501
	RETURN
END


IF ( @terms_type = 1 )
BEGIN
	SELECT @date_discount = @date_doc + @discount_days
	RETURN
END
ELSE IF ( @terms_type = 3 )
BEGIN
	SELECT @date_discount = @date_disc
	RETURN
END
ELSE IF ( @terms_type = 2 )
BEGIN
	
	IF ( @date_doc < 0 )
	BEGIN
		SELECT @app_error_flag = -502
		RETURN
	END
	EXEC appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc

	
	EXEC appjuldt_sp @year, @month, @discount_days, @date_discount OUTPUT

	
	IF ( ( @date_discount - @date_doc ) < @min_days_due )
	BEGIN
		SELECT @month = @month + 1

		IF ( @month > 12 )
		BEGIN
			SELECT @month = 1
			SELECT @year = @year + 1
		END

		
		EXEC appjuldt_sp @year, @month, @discount_days, @date_discount OUTPUT
	END
END
ELSE
	SELECT @app_error_flag = -503






GO
GRANT EXECUTE ON  [dbo].[appdtdsc_sp] TO [public]
GO
