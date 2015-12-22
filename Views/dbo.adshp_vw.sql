SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


Create View [dbo].[adshp_vw]
As





















select 
	order_no ,
	cust_code ,
	ship_to ,
	ship_to_name ,
	location ,
	cust_po ,
	routing,
	freight_to,	
	fob,	
	curr_key,
	total_amt_order ,
	freight=tot_ord_freight,
	total_invoice ,
	invoice_no ,
	date_invoice=invoice_date ,
	date_entered,
	date_printed ,
	date_sch_ship= sch_ship_date ,
	date_shipped ,
	status ,
	status_desc = 
		CASE status
			WHEN 'R' THEN 'Shipped/Ready to invoice'
			WHEN 'S' THEN 'Shipped/Invoice'
			WHEN 'T' THEN 'Shipped/Transerred to AR'
			ELSE ''
		END, 
	who_entered,
	back_ord_flag ,
	back_order_desc =
		CASE back_ord_flag 
			WHEN '0' THEN 'Allow Backorder'
			WHEN '1' THEN 'Ship Complete'
			WHEN '2' THEN 'Allow Partial'
			ELSE ''
		END, 
	ext, 

	x_order_no=order_no ,
	x_total_amt_order=total_amt_order ,
	x_freight=tot_ord_freight,
	x_total_invoice=total_invoice ,
	x_invoice_no=invoice_no ,
	x_date_invoice=invoice_date ,
	x_date_entered=date_entered,
	x_date_printed=date_printed ,
	x_date_sch_ship= sch_ship_date ,
	x_date_shipped=date_shipped ,
	x_ext=ext 

from
	orders
where 	type = "I"
	and (status ='R' or status = 'S' or status = 'T')
GO
GRANT REFERENCES ON  [dbo].[adshp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adshp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adshp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adshp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adshp_vw] TO [public]
GO
