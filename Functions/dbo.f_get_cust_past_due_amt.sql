SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- v1.0 TAG	- Figure out past due balance for customer
          
create FUNCTION [dbo].[f_get_cust_past_due_amt](@cust_code VARCHAR(8))          
RETURNS DECIMAL (20,8)           
AS            
BEGIN
	declare @net_past_due float
	select @net_past_due = sum((x.amt_net - x.amt_paid_to_date) * 
	 (SIGN(1 + SIGN(DATEDIFF(DD,'1/1/80',GETDATE())+722815 - X.DATE_DUE))* SIGN(1 - X.PAID_FLAG)))
	from artrx x (nolock) where customer_code = @cust_code

	return @net_past_due
END 
GO
