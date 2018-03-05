SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.3 13/03/2013 - Fix issues with due date calculation
-- v1.4 15/05/2014 - Further fix
-- v1.5 27/01/2016 - February again!!
-- v1.6 31/08/2017 - Fix issue with month not incrementing correctly
-- v1.7 03/11/2017 - Fix for Oct 31st invoices
-- v1.8 26/01/2018 - If due date is past statement date then increment month but reduce day
-- v1.9 20/02/2018 - Re-write to fix issues
CREATE PROC [dbo].[CVO_CalcDueDate_sp]  @customer_code varchar(8),  
         @date_doc  int,  
         @date_due  int OUTPUT,  
         @terms_code  varchar(8) = ''    
AS  
BEGIN  
	-- DECLARATIONS  
	DECLARE @year   int,  
			@month   int,  
			@day   int,  
			@statement_day int,  
			@days_due  int,  
			@skip   int, -- v1.2  
			@max_days  int, -- v1.2  
			@orig_month int, -- v1.3
			@month_multi int -- v1.9
  
	SET @days_due = 0  
	SET @skip = 0 -- v1.2  
  
	IF @terms_code <> ''  
	BEGIN  
		SELECT	@days_due = days_due  
		FROM	dbo.arterms (NOLOCK)  
		WHERE	terms_code = @terms_code  
	END  
   
	-- Get the statement day  
	SET @statement_day = 0  
  
	SELECT	@statement_day = ISNULL(number,0)  
	FROM	dbo.arcycle a (NOLOCK)  
	JOIN	dbo.arcust b (NOLOCK)  
	ON		a.cycle_code = b.stmt_cycle_code  
	WHERE	b.customer_code = @customer_code  
	AND		cycle_type = 5  
	AND		use_type = 2  
  
	-- if we are here then there are no installments, so just updated the statement date  
	IF @statement_day > 0 AND @statement_day < 32  
	BEGIN  

		EXEC dbo.appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc 

		IF (@days_due IN (30,60,90,120))
		BEGIN
			SET @month_multi = @days_due / 30
		
			SET @month = @month + @month_multi

			IF (@month > 12)
			BEGIN
				SET @year = @year + 1
				SET @month = @month - 12
			END

			SET @max_days = 31  
  
			IF @month IN (2)  
			BEGIN  
				IF (((@year%100 != 0) AND (@year%400 = 0)) OR (@year%400 = 0))  
					SET @max_days = 29  
				ELSE  
					SET @max_days = 28    
			END  
  
			IF @month IN (4,6,9,11)  
			BEGIN  
				SET @max_days = 30  
			END  

			IF (@day > @max_days)
				SET @day = @max_days

			EXEC dbo.appjuldt_sp @year, @month, @day, @date_doc OUTPUT 
		END
		ELSE
		BEGIN
			SET @date_doc = @date_doc + @days_due
		END
		  
		-- Break out the invoice date  
		EXEC dbo.appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc 
				 
		IF (@day > @statement_day)
		BEGIN
			SET @day = @statement_day
			SET @month = @month + 1

			IF (@month > 12)
			BEGIN
				SET @year = @year + 1
				SET @month = 1
			END

			SET @max_days = 31  
  
			IF @month IN (2)  
			BEGIN  
				IF (((@year%100 != 0) AND (@year%400 = 0)) OR (@year%400 = 0))  
					SET @max_days = 29  
				ELSE  
					SET @max_days = 28    
			END  
  
			IF @month IN (4,6,9,11)  
			BEGIN  
				SET @max_days = 30  
			END  

			IF (@day > @max_days)
				SET @day = @max_days

		END
		ELSE
		BEGIN
			SET @day = @statement_day
		END

		EXEC dbo.appjuldt_sp @year, @month, @day, @date_due OUTPUT -- v1.6

	END
	ELSE  
	BEGIN  
		SET @date_due = @date_doc  
	END    
END  

GO

GRANT EXECUTE ON  [dbo].[CVO_CalcDueDate_sp] TO [public]
GO
