SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.3 13/03/2013 - Fix issues with due date calculation
-- v1.4 15/05/2014 - Further fix
-- v1.5 27/01/2016 - February again!!
-- v1.6 31/08/2017 - Fix issue with month not incrementing correctly
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
   @orig_month int -- v1.3
  
 SET @days_due = 0  
 SET @skip = 0 -- v1.2  
  
 IF @terms_code <> ''  
 BEGIN  
  SELECT @days_due = days_due  
  FROM dbo.arterms (NOLOCK)  
  WHERE terms_code = @terms_code  
  
 END  
   
 -- Get the statement day  
 SET @statement_day = 0  
  
 SELECT @statement_day = ISNULL(number,0)  
 FROM dbo.arcycle a (NOLOCK)  
 JOIN dbo.arcust b (NOLOCK)  
 ON  a.cycle_code = b.stmt_cycle_code  
 WHERE b.customer_code = @customer_code  
 AND  cycle_type = 5  
 AND  use_type = 2  
  
 -- if we are here then there are no installments, so just updated the statement date  
 IF @statement_day > 0 AND @statement_day < 32  
 BEGIN  
  
  -- Break out the invoice date  
  EXEC dbo.appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc  
  SET @orig_month = @month -- v1.3

  -- Calculate the next statement date  
  IF (@day > @statement_day)   
  BEGIN  
   -- Increment the month  
   SET @month = @month + 1  
   IF @month > 12  
   BEGIN  
    -- Increment the year  
    SET @year = @year + 1  
    SET @month = 1  
   END  

	-- If we have incremented the dates then rebuild the date_doc
	EXEC dbo.appjuldt_sp @year, @month, @day, @date_doc OUTPUT -- v1.6

  END  
  

  -- Validate the day  
  IF @statement_day > 28  
  BEGIN  
   IF @month IN (2)  
   BEGIN  
    IF (((@year%100 != 0) AND (@year%400 = 0)) OR (@year%400 = 0))  
     SET @statement_day = 29  
    ELSE  
     SET @statement_day = 28  
   
   END  
  
   IF @month IN (4,6,9,11)  
   BEGIN  
    IF @statement_day = 31  
     SET @statement_day = 30  
   END  
  END  
  
  -- v1.2 Start  
  -- Get the max days in the statement month  
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
  

  -- If the terms are greater than the max_days then do inv_date + terms else inv_date to next statement + terms  
  IF @days_due > @max_days  
  BEGIN  
   SET @skip = 1  
   SET @date_doc = @date_doc + @days_due  

   EXEC dbo.appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_doc
   IF (	@orig_month = 2 and @max_days = 28) -- v1.4
		SET @day = @statement_day -- -- v1.3


   -- Calculate the next statement date  
-- TAG -- 2/28/2013 IF (@day > @statement_day)   
   --IF (@day >= @statement_day) -- v1.3  
   IF ((@day > @statement_day) OR (@orig_month = 1 AND @day >= @statement_day AND @days_due < 31)) -- v1.3 v1.5 

  
   BEGIN  
    -- Increment the month  
    SET @month = @month + 1  
    IF @month > 12  
    BEGIN  
     -- Increment the year  
     SET @year = @year + 1  
     SET @month = 1  
    END  
   END  
  

   -- Validate the day  
   IF @statement_day > 28  
   BEGIN  
    IF @month IN (2)  
    BEGIN  
     IF (((@year%100 != 0) AND (@year%400 = 0)) OR (@year%400 = 0))  
      SET @statement_day = 29  
     ELSE  
      SET @statement_day = 28  
    
    END  
  
    IF @month IN (4,6,9,11)  
    BEGIN  
     IF @statement_day = 31  
      SET @statement_day = 30  
    END  
   END  
  END  
  -- v1.2 End  
    
  -- Set the statement day  
  SET @day = @statement_day  
  
  
  -- Get the julian date for the statement date  
  EXEC dbo.appjuldt_sp @year, @month, @day, @date_due OUTPUT  
  
  -- Add the terms and recalc the statement date  
  IF (@days_due <> 0) AND (@skip = 0) -- v1.2 If we have forced the alternate calc then do not do this  
  BEGIN  
   -- Add on the terms  
   SET @date_due = @date_due + @days_due  
   
   -- Break out the invoice date  
   EXEC dbo.appdtjul_sp @year OUTPUT, @month OUTPUT, @day OUTPUT, @date_due  
     
   -- Calculate the next statement date  
   IF (@day > @statement_day)   
   BEGIN  
    -- Increment the month  
    SET @month = @month + 1  
    IF @month > 12  
    BEGIN  
     -- Increment the year  
     SET @year = @year + 1  
     SET @month = 1  
    END  
   END  
  
   -- Validate the day  
   IF @statement_day > 28  
   BEGIN  
    IF @month IN (2)  
    BEGIN  
     IF (((@year%100 != 0) AND (@year%400 = 0)) OR (@year%400 = 0))  
      SET @statement_day = 29  
     ELSE  
      SET @statement_day = 28  
    
    END  
  
    IF @month IN (4,6,9,11)  
    BEGIN  
     IF @statement_day = 31  
      SET @statement_day = 30  
    END  
   END  
     
   -- Set the statement day  
   SET @day = @statement_day  
  
   -- Get the julian date for the statement date  
   EXEC dbo.appjuldt_sp @year, @month, @day, @date_due OUTPUT  
  
  END  
 END  
 ELSE  
 BEGIN  
  SET @date_due = @date_doc  
 END  
  
  
END  

GO

GRANT EXECUTE ON  [dbo].[CVO_CalcDueDate_sp] TO [public]
GO
