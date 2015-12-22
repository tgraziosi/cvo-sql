SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[CVO_PECH_Shipping_Check_sp] 
AS

select sold_to,order_no, cust_po, cust_code,date_entered, WHO_ENTERED,status, DATE_SHIPPED, WHO_PICKED from orders_all (nolock)
where sold_to in ('pechlab','gpec')
and date_entered > GETDATE()-2

GO
