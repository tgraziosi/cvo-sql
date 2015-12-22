SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CVO_SalesByOrderTypeAndRegion_vw]
AS
SELECT 
'E' as source,
ord.cust_code,
ShipToCode = 
	CASE WHEN EXISTS(select * from armaster_all cus where ord.ship_to = cus.customer_code) then ''
	else isnull(ord.ship_to,'')
-- deals with Global ship-to's which have their own armaster entry
END,
-- ord.ship_to as ship_to_code,
Ord.ship_to_region as terr_code,  -- tag 12/14 - per Finance request
terr.territory_desc AS terr_name, 
Ord.salesperson, 
sc_1.salesperson_name AS sc_name,
CASE ord.type 
	WHEN 'I' THEN CAST(ord.user_category AS varchar(2)) 
	WHEN 'C' THEN 'CR' 
END AS Order_type, 
Ord.user_category, 
Ord.type, 
Ord.status, 
Ord.order_no, 
Ord.ext, 
ord.invoice_no,
Ord.invoice_date, 

case ord.type
	when 'C' then -1*Ord.total_invoice
	else ord.total_invoice
end as Tot_invoice,
case ord.type
	when 'C' then -1*ord.total_amt_order
	else ord.total_amt_order
end as tot_amt_order,

CASE ord.type 
	WHEN 'I' THEN 
	 ISNULL ((SELECT SUM(shipped) 
     FROM   ord_list AS od
     WHERE (od.order_no = ord.order_no) AND (od.order_ext = ord.ext)
     GROUP BY od.order_no), 0)
	WHEN 'C' THEN 
	  ISNULL ((SELECT SUM(cr_shipped) 
     FROM   ord_list AS od
     WHERE (od.order_no = ord.order_no) AND (od.order_ext = ord.ext)
     GROUP BY od.order_no)*-1, 0) 
END AS qty_shipped

FROM  
   dbo.orders_all Ord left join cvo_orders_all co ON ord.order_no = co.order_no AND ord.ext = co.ext
	left join  
   dbo.arterr terr ON Ord.ship_to_region = terr.territory_code 
	left JOIN
   dbo.arsalesp sc_1 ON Ord.salesperson = sc_1.salesperson_code
where
 (ord.status >= 'R' and ord.status <> 'V')
--  and (ord.invoice_date between '08/13/2011' and '11/13/2011')

UNION ALL

SELECT 
'M' as Source,
ord.cust_code,
ShipToCode = 
	CASE WHEN EXISTS(select * from armaster_all cus where ord.ship_to = cus.customer_code)
	then ''
	else isnull(ord.ship_to,'')
-- deals with Global ship-to's which have their own armaster entry
END,
-- isnull(ord.ship_to,'') as ship_to_code,
cus.territory_code, 
terr.territory_desc AS terr_name, 
scxref.salesperson_code, 
scxref.salesperson_name AS sc_name,
CASE ord.type 
	WHEN 'I' THEN CAST(ord.user_category AS varchar(2)) 
	WHEN 'C' THEN 'CR' 
	ELSE 'NA'
END AS Order_type, 
Ord.user_category, 
Ord.type, 
Ord.status, 
Ord.order_no, 
Ord.ext, 
ord.invoice_no,
Ord.invoice_date, 
case ord.type
	when 'C' then -1*Ord.total_invoice
	else ord.total_invoice
end as Tot_invoice,
ord.total_amt_order,

CASE ord.type 
	WHEN 'I' THEN 
	 ISNULL ((SELECT SUM(shipped) 
     FROM   cvo_ord_list_hist AS od
     WHERE (od.order_no = ord.order_no) AND (od.order_ext = ord.ext)
     GROUP BY od.order_no), 0)
	WHEN 'C' THEN 
	  ISNULL ((SELECT SUM(shipped) 
     FROM   cvo_ord_list_hist AS od
     WHERE (od.order_no = ord.order_no) AND (od.order_ext = ord.ext)
     GROUP BY od.order_no)*-1, 0) 
	ELSE 0
END AS qty_shipped

FROM  
	dbo.cvo_orders_all_hist Ord 
	left join  
	dbo.armaster_all cus on
	(cus.customer_code = ord.cust_code 
	and cus.ship_to_code = 
	CASE 
		WHEN EXISTS(select * from armaster_all cus where ord.ship_to = cus.customer_code) then ''
		when ord.ship_to='I' then '' 
		else isnull(ord.ship_to,'')
	-- deals with Global ship-to's which have their own armaster entry
	END )
-- isnull(ord.ship_to,''))
	left join
    dbo.arterr terr ON cus.territory_code = terr.territory_code 
--	left JOIN
--   dbo.arsalesp sc_1 ON Ord.salesperson = sc_1.salesperson_code
	left join
	cvo_salespersonxref scxref on ord.salesperson = scxref.scode 
where
 (ord.status >= 'R' and ord.status <> 'V')
-- and (ord.invoice_date between '7/13/2010' and '7/13/2010')
GO
GRANT REFERENCES ON  [dbo].[CVO_SalesByOrderTypeAndRegion_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_SalesByOrderTypeAndRegion_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_SalesByOrderTypeAndRegion_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_SalesByOrderTypeAndRegion_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_SalesByOrderTypeAndRegion_vw] TO [public]
GO
