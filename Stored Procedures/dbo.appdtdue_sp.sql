SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                











CREATE PROC	[dbo].[appdtdue_sp]	@module_id	int,
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
        @end_month_flag         tinyint

SELECT	@end_month_flag = 0




IF ( @terms_code = "" OR @terms_code IS NULL )
BEGIN
	SELECT @date_due = @date_doc
	RETURN
END




IF ( @module_id = 2000 )
	SELECT	@days_due = days_due,
		@date_due = date_due,
		@terms_type = terms_type,
		@min_days_due = min_days_due
	FROM	arterms
	WHERE	terms_code = @terms_code

ELSE IF ( @module_id = 4000 )
	SELECT	@days_due = days_due,
		@date_due = date_due,
		@terms_type = terms_type,
		@min_days_due = min_days_due
	FROM	apterms
	WHERE	terms_code = @terms_code







IF ( @terms_type = 1 )
BEGIN
	SELECT	@date_due = @date_doc + @days_due
	RETURN
END
ELSE IF ( @terms_type = 3 )
	RETURN
ELSE IF ( @terms_type = 4 ) AND ( @module_id = 4000 )	
	RETURN						







EXEC	appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc
EXEC	appmoday_sp @month, @year, @max_day OUTPUT

IF ( @days_due = @max_day )
	SELECT @end_month_flag = 1





EXEC    appjuldt_sp @year, @month, @days_due, @date_due OUTPUT





IF ( (@days_due = 31 ) AND ( @min_days_due = 31 ) )
BEGIN
	IF ( @month = 12 )
        	SELECT @max_day = 31,  	
			@year = @year + 1,	
			@month = 1	  	
      	ELSE 
	BEGIN
		SELECT @month = @month + 1	
		EXEC appmoday_sp @month, @year, @max_day OUTPUT
       END
	
       EXEC appjuldt_sp @year, @month, @max_day, @date_due OUTPUT
	RETURN
END






WHILE   ( ( @date_due - @date_doc ) < @min_days_due )
BEGIN

	


	SELECT @month = @month + 1

	


	IF ( @month > 12 )
        BEGIN
                SELECT  @month = 1
                SELECT  @year = @year + 1
        END

	


	IF ( @end_month_flag = 1 )
         begin
		EXEC    appmoday_sp @month, @year, @day OUTPUT
         end 
	


        EXEC    appjuldt_sp @year, @month,@days_due, @date_due OUTPUT

END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appdtdue_sp] TO [public]
GO
