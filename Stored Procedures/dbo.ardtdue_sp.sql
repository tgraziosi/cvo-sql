SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\AR\PROCS\ardtdue.SPv - e7.2.2 : 1.3
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1996 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1996 Epicor Software Corporation, 1996  
                 All Rights Reserved                    
*/                                                



CREATE PROC	[dbo].[ardtdue_sp]	
				@terms_code	char(8),
				@date_doc	int,
				@date_due	int OUTPUT
AS 

DECLARE	@days_due		smallint,
	@terms_type		smallint,
	@min_days_due		smallint,
	@year			smallint,
	@month			smallint,
	@day			smallint,
	@max_day		smallint,
	@end_month_flag tinyint
	 
SELECT	@end_month_flag = 0


IF ( @terms_code = "" OR @terms_code IS NULL )
BEGIN
	SELECT @date_due = @date_doc
	RETURN
END


	SELECT	@days_due = days_due,
		@date_due = date_due,
		@terms_type = terms_type,
		@min_days_due = min_days_due
	FROM	arterms
	WHERE	terms_code = @terms_code



IF ( @terms_type = 1 )
BEGIN
	SELECT	@date_due = @date_doc + @days_due
	RETURN
END
ELSE IF ( @terms_type = 3 )
	RETURN


EXEC	appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc
EXEC	appmoday_sp @month, @year, @max_day OUTPUT

IF ( @days_due = @max_day )
	SELECT @end_month_flag = 1



IF ( @days_due <= @max_day )
	EXEC appjuldt_sp @year, @month, @days_due, @date_due OUTPUT
ELSE
BEGIN
	IF ( @month = 2 ) AND 
	 ( (( @year%100 != 0 ) AND ( @year%400 = 0 )) OR (@year%400 = 0) )			
		EXEC appjuldt_sp @year, @month, 29, @date_due OUTPUT
	ELSE
		EXEC appjuldt_sp @year, @month, @max_day, @date_due OUTPUT
END


WHILE ( ( @date_due - @date_doc ) < @min_days_due )
BEGIN

	
	SELECT @month = @month + 1

	
	IF ( @month > 12 )
 BEGIN
 SELECT @month = 1
 SELECT @year = @year + 1
 END

	
	IF ( @end_month_flag = 1 )
		EXEC appmoday_sp @month, @day OUTPUT

	
 EXEC appjuldt_sp @year, @month, @days_due, @date_due OUTPUT

END




/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ardtdue_sp] TO [public]
GO
