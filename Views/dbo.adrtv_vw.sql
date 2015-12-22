SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[adrtv_vw] as


/*
-- Original code modified DMoon 5/25/2010

select 
	rtv_no,
	vendor_no,	
	location,

	ship_via,
	fob ,
	terms ,
	attn,
	vend_rma_no ,
	restock_fee,
	freight,
	tax_amt,
	total_amt_order,
	
	date_of_order ,
	date_order_due,
	
	status ,
	
	status_desc = 
		CASE status
			WHEN 'N' THEN 'Open'
			WHEN 'S' THEN 'Closed'
			WHEN 'T' THEN 'Transferred to AP'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	post_to_ap,
	post_ap_desc=
		CASE post_to_ap
			WHEN 'N' THEN 'No'
			WHEN 'Y'THEN 'Yes'
			ELSE ''
		END,
	match_ctrl_int=convert(varchar(16), match_ctrl_int),

	x_rtv_no = rtv_no,
	x_restock_fee = restock_fee,
	x_freight = freight,
	x_tax_amt = tax_amt,
	x_total_amt_order = total_amt_order,
	
	x_date_of_order = ((datediff(day, '01/01/1900', date_of_order) + 693596)) + (datepart(hh,date_of_order)*.01 + datepart(mi,date_of_order)*.0001 + datepart(ss,date_of_order)*.000001),
	x_date_order_due = ((datediff(day, '01/01/1900', date_order_due) + 693596)) + (datepart(hh,date_order_due)*.01 + datepart(mi,date_order_due)*.0001 + datepart(ss,date_order_due)*.000001),
	
	x_match_ctrl_int=convert(varchar(16), match_ctrl_int)


from
	rtv_all

*/

-- revised to include vendor name
select 
	a.rtv_no,
	a.vendor_no,
	b.vendor_name,	
	a.location,

	a.ship_via,
	a.fob ,
	a.terms ,
	a.attn,
	a.vend_rma_no ,
	a.restock_fee,
	a.freight,
	a.tax_amt,
	a.total_amt_order,
	
	a.date_of_order ,
	a.date_order_due,
	
	a.status ,
	
	status_desc = 
		CASE a.status
			WHEN 'N' THEN 'Open'
			WHEN 'S' THEN 'Closed'
			WHEN 'T' THEN 'Transferred to AP'
			WHEN 'V' THEN 'Void'
			ELSE ''
		END, 
	a.post_to_ap,
	post_ap_desc=
		CASE a.post_to_ap
			WHEN 'N' THEN 'No'
			WHEN 'Y'THEN 'Yes'
			ELSE ''
		END,
	match_ctrl_int=convert(varchar(16), a.match_ctrl_int),

	x_rtv_no = a.rtv_no,
	x_restock_fee = a.restock_fee,
	x_freight = a.freight,
	x_tax_amt = a.tax_amt,
	x_total_amt_order = a.total_amt_order,
	
	x_date_of_order = ((datediff(day, '01/01/1900', a.date_of_order) + 693596)) + (datepart(hh,a.date_of_order)*.01 + datepart(mi,a.date_of_order)*.0001 + datepart(ss,a.date_of_order)*.000001),
	x_date_order_due = ((datediff(day, '01/01/1900', a.date_order_due) + 693596)) + (datepart(hh,a.date_order_due)*.01 + datepart(mi,a.date_order_due)*.0001 + datepart(ss,a.date_order_due)*.000001),
	
	x_match_ctrl_int=convert(varchar(16), a.match_ctrl_int)


from
	rtv_all a, apvend b
where a.vendor_no = b.vendor_code
 
GO
GRANT REFERENCES ON  [dbo].[adrtv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adrtv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adrtv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adrtv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adrtv_vw] TO [public]
GO
