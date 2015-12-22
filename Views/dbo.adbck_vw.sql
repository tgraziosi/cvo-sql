SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adbck_vw] as

select 
	order_no ,
	ext,
	cust_code ,
	ship_to ,
	ship_to_name ,
	location ,
	cust_po ,
		
	curr_key,

	total_amt_order ,
	total_tax =tot_ord_tax ,
	total_discount=tot_ord_disc ,
	total_invoice ,

	invoice_no ,
	
	date_invoice = invoice_date ,
	date_entered ,
	date_sch_ship = sch_ship_date ,
	date_shipped ,
	
	status ,
	status_desc = 
		CASE status
			WHEN 'N' THEN 'New'
			WHEN 'Q' THEN 'Open/Printed'
			WHEN 'R' THEN 'Shipped/Ready to invoice'
			WHEN 'S' THEN 'Shipped/Invoice'
			WHEN 'T' THEN 'Shipped/Transerred to AR'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 

	who_entered,
	order_ctrl_num = convert(varchar(10), order_no) + '-' 
			 + convert(varchar(10), ext),

	x_total_amt_order=total_amt_order ,
	x_total_tax =tot_ord_tax ,
	x_total_discount=tot_ord_disc ,
	x_total_invoice=total_invoice ,
	x_date_invoice = invoice_date ,
	x_date_entered=date_entered ,
	x_date_sch_ship = sch_ship_date ,
	x_date_shipped =date_shipped


from
	orders

where 	ext != 0 
	and blanket != 'Y'
	and type = 'I'

 
GO
GRANT REFERENCES ON  [dbo].[adbck_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adbck_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adbck_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adbck_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adbck_vw] TO [public]
GO
