SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
    
    
    
CREATE PROCEDURE [dbo].[adm_mccurate_sp]     
 @apply_date   int,    
 @from_currency  varchar(8),    
 @to_currency  varchar(8),    
 @rate_type varchar(8),    
 @rate_used float = NULL OUTPUT,    
 @return_row smallint = 1,    
 @divide_flag  smallint = NULL OUTPUT    
AS    
  declare @retval int    
  declare @x_rate_used float, @x_divide_flag smallint    
    
  select @x_rate_used = @rate_used,    
    @x_divide_flag = @divide_flag    
    
  
  exec @retval = CVO_Control..mccurate_sp    
    @apply_date,@from_currency,@to_currency,@rate_type,    
    @x_rate_used OUTPUT,@return_row,@x_divide_flag OUTPUT    
    
  select @rate_used = @x_rate_used,    
    @divide_flag = @x_divide_flag    
    
  return @retval 
GO
GRANT EXECUTE ON  [dbo].[adm_mccurate_sp] TO [public]
GO
