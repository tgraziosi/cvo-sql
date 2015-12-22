SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_order_tax_Log_vw] 
as
select status, order_no, ext, cust_code, ship_to, ship_to_name,
ship_to_city, ship_to_state, ship_to_zip, date_entered, who_entered from orders (nolock) 
where (tax_valid_ind = 0 or addr_valid_ind=0) and status <'T' and status <> 'V'
GO
GRANT REFERENCES ON  [dbo].[cvo_order_tax_Log_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_order_tax_Log_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_order_tax_Log_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_order_tax_Log_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_order_tax_Log_vw] TO [public]
GO
