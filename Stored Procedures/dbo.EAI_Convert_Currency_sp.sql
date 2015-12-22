SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[EAI_Convert_Currency_sp] 
                 @apply_date int = 0,
                 @from_currency varchar(8),
                 @to_currency varchar(8),
                 @rate_type varchar(8),
                 @original_amount decimal = 0,
                 @converted_amount decimal OUTPUT
AS
BEGIN
 
   DECLARE @rate_used    float,
           @Conv_Amt_d   decimal,
           @Conv_Amt_vc  varchar(20)

   IF (@apply_date = 0)
   BEGIN
      SELECT @apply_date = max(convert_date)
      FROM   CVO_Control..mccurtdt						 
      WHERE  from_currency = @from_currency
      AND    to_currency = @to_currency
      AND    rate_type = @rate_type
   END

   EXEC CVO_Control..mccurate_sp @apply_date, @from_currency, @to_currency, @rate_type, @rate_used OUTPUT, 0

   SELECT @converted_amount = ( SIGN(1 + SIGN(@rate_used))*(@rate_used) + (SIGN(ABS(SIGN(ROUND(@rate_used,6))))/(@rate_used + SIGN(1 - ABS(SIGN(ROUND(@rate_used,6)))))) * SIGN(SIGN(@rate_used) - 1) ) * @original_amount  
   SELECT @Conv_Amt_vc = convert(varchar(20),round(@converted_amount,0))
   SELECT @Conv_Amt_vc Conv_Amt
END

GO
GRANT EXECUTE ON  [dbo].[EAI_Convert_Currency_sp] TO [public]
GO
