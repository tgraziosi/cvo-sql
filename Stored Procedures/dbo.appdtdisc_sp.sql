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









 


CREATE PROC	[dbo].[appdtdisc_sp]	@module_id	int,
				@terms_code	char(8),
				@date_doc	int,
				@date_disc	int OUTPUT
AS 

DECLARE	@days_due		smallint,
	@terms_type		smallint,
	@min_days_due		smallint,
	@year			smallint,
	@month			smallint,
	@day			smallint,
	@max_day		smallint,
        @end_month_flag         tinyint,
        @disc_days		smallint,
	@cur_terms_code         varchar(30),
	@disc_prc               float,
	@date_discount          int
         

SELECT	@end_month_flag = 0




IF ( @terms_code = "" OR @terms_code IS NULL )
BEGIN
	SELECT @date_disc = @date_doc
	RETURN
END




















SELECT @cur_terms_code = ' '

SELECT @disc_days = d.discount_days,
       @terms_type = h.terms_type, 
       @date_discount = d.date_discount, 
       @min_days_due = h.min_days_due, 
       @disc_prc = d.discount_prc, 
       @cur_terms_code = h.terms_code,
       @days_due = h.days_due
FROM aptermsd d, apterms h 
WHERE h.terms_code = d.terms_code 
AND h.terms_code = @terms_code
AND d.sequence_id = (SELECT MIN(sequence_id) FROM aptermsd)

IF (@cur_terms_code = ' ' )
BEGIN
	SELECT  @date_disc = @date_doc + @days_due
	SELECT  @date_disc = 0
	RETURN
END
IF (@disc_prc = 0)
BEGIN
	SELECT  @date_disc = 0 
	RETURN
END


IF ( @terms_type = 1 OR (@terms_type = 2 AND @disc_days=0 )OR @terms_type = 4 )
BEGIN
	SELECT  @date_disc = @date_doc + @disc_days
	RETURN
END





IF ( @terms_type = 3)
BEGIN
SELECT  @date_disc =  @date_discount
RETURN
END 










				


EXEC	appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc
EXEC	appmoday_sp @month, @year, @max_day OUTPUT


IF ( @disc_days = @max_day )
	SELECT @end_month_flag = 1

EXEC    appjuldt_sp @year, @month, @disc_days, @date_disc OUTPUT

IF (@date_disc<0) 
BEGIN
 Select  @date_disc = 0
 RETURN
END



















WHILE   ( ( @date_disc - @date_doc ) < @min_days_due )
BEGIN

	SELECT @month = @month + 1

	
	IF ( @month > 12 )
        BEGIN
                SELECT  @month = 1
                SELECT  @year = @year + 1
        END


	IF ( @end_month_flag = 1 )
	begin
		EXEC    appmoday_sp @month, @year, @day OUTPUT ---ggr  @days_due ,@day
	
	end
	else
        begin
	   SELECT  @day = @disc_days	
	end
	


        EXEC    appjuldt_sp @year, @month, @day, @date_disc OUTPUT --ggr @day
        
       IF (@date_disc<0) 
        BEGIN
 		Select  @date_disc = 0
 		RETURN
	END
    

END

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[appdtdisc_sp] TO [public]
GO
