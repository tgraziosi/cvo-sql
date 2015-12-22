SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[CVO_PECH_Shipping_Check_vw] AS

select sold_to,order_no, cust_po, cust_code,date_entered, WHO_ENTERED,
case status when 'v' then 'void'
			when 't' then 'Invoice'
			when 's' then 'Shipped/Posed'
			when 'r' then 'Ready/Posted'
			when 'q' then 'Open/Printed'
			when 'P' then 'Open/Picked'
			when 'N' then 'OPEN ORDER' 
			else 'HOLD'
			END AS STATUS,
 DATE_SHIPPED, WHO_PICKED from orders_all (nolock)
where sold_to in ('pechlab','gpec')
and type='i'
and date_entered > GETDATE()-2
GO
