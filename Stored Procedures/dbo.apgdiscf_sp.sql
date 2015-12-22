SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[apgdiscf_sp] @pa_date_doc int, @date_doc int, @terms_code varchar(8), @discount_flag smallint OUTPUT 
AS DECLARE @terms_type int,  @days_due int,  @days_discount int,  @date_invoice int, 
 @dis_year int,  @dis_month int,  @dis_day int,  @discount_val float  EXEC appdtjul_sp @dis_year OUTPUT, @dis_month OUTPUT, @dis_day OUTPUT, @pa_date_doc 
 SELECT @terms_type = terms_type,  @days_due = days_due,  @days_discount = discount_days 
 FROM apterms  WHERE terms_code = @terms_code  IF @terms_type = 1  BEGIN  SELECT @discount_val = ISNULL(MAX(discount_days),0) 
 FROM aptermsd  WHERE terms_code = @terms_code  AND (@date_doc + @days_discount - @pa_date_doc) <= discount_days 
 SELECT @discount_flag = SIGN(@discount_val)  END  IF @terms_type = 2  BEGIN  SELECT @discount_val = ISNULL(MAX(discount_days),0) 
 FROM aptermsd  WHERE terms_code = @terms_code  AND @dis_day <= discount_days  SELECT @discount_flag = SIGN(@discount_val) 
 END  IF @terms_type = 3  BEGIN  SELECT @discount_val = ISNULL(MAX(date_discount),0) 
 FROM aptermsd  WHERE terms_code = @terms_code  AND @pa_date_doc <= discount_days 
 SELECT @discount_flag = SIGN(@discount_val)  END  IF @terms_type = 4  BEGIN  IF @dis_month + @days_due > 12 
 BEGIN  SELECT @days_due = @days_due - 12,  @dis_year = @dis_year + 1  END  ELSE 
 SELECT @dis_month = @dis_month + @days_due  EXEC appdtjul_sp @dis_year OUTPUT, @dis_month OUTPUT, @dis_day OUTPUT, @discount_val 
 SELECT @discount_val = @discount_val - @pa_date_doc  SELECT @discount_flag = SIGN(@discount_val) 
 IF @discount_flag < 0  SELECT @discount_flag = 0  END RETURN 
GO
GRANT EXECUTE ON  [dbo].[apgdiscf_sp] TO [public]
GO
