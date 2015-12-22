SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
Create procedure [dbo].[CVO_BeginCustomerLoad]
AS
exec preparecustomers
delete ztemp_customer where row_action=0
delete ztemp_customer where customer_code IS NULL
exec CVO_CustomerLoad

GO
GRANT EXECUTE ON  [dbo].[CVO_BeginCustomerLoad] TO [public]
GO
