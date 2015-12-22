SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adtolr_vw] as

select  tolerance_cd,
	description,
	receipts_qty_action = 
		CASE receipts_qty_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	matching_qty_action =
		CASE matching_qty_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	qty_over_pct,
	qty_under_pct,
	receipts_unit_price_action =
		CASE receipts_unit_price_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	matching_unit_price_action =
		CASE matching_unit_price_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	unit_price_over_pct,
	unit_price_under_pct,
	tax_action =
		CASE tax_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	tax_over_pct,
	tax_under_pct,
	total_amt_action =
		CASE total_amt_action
			WHEN 'N' THEN 'No Action'
			WHEN 'W' THEN 'Warning'
			WHEN 'E' THEN 'Error'
			ELSE ''
		END,
	total_amt_over_pct,
	total_amt_under_pct,
	amt_over_ext_price,
	amt_under_ext_price,
	amt_over_tax,
	amt_under_tax,
	amt_under_total_order,
	amt_over_total_order,
	void,
	void_who,
	void_date, 

	x_unit_price_over_pct = unit_price_over_pct,
	x_unit_price_under_pct = unit_price_under_pct,
	x_tax_over_pct = tax_over_pct,
	x_tax_under_pct = tax_under_pct,
	x_total_amt_over_pct = total_amt_over_pct,
	x_total_amt_under_pct = total_amt_under_pct,
	x_amt_over_ext_price = amt_over_ext_price,
	x_amt_under_ext_price = amt_under_ext_price,
	x_amt_over_tax = amt_over_tax,
	x_amt_under_tax = amt_under_tax,
	x_amt_under_total_order = amt_under_total_order,
	x_amt_over_total_order = amt_over_total_order,
	x_void_date = ((datediff(day, '01/01/1900', void_date) + 693596)) + (datepart(hh,void_date)*.01 + datepart(mi,void_date)*.0001 + datepart(ss,void_date)*.000001)

from tolerance

 
GO
GRANT REFERENCES ON  [dbo].[adtolr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adtolr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adtolr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adtolr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adtolr_vw] TO [public]
GO
