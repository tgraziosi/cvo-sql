SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[aditm_vw] as

select 
	inv_master.part_no,
	description,
	status,
	status_desc = 
		CASE status
			WHEN 'C' THEN 'Configured Kit'
			WHEN 'K' THEN 'Auto Kit'
			WHEN 'H' THEN 'Make/Routed'
			WHEN 'M' THEN 'Make'
			WHEN 'P' THEN 'Purchase'
			WHEN 'Q' THEN 'Purchase/Outsource'
			WHEN 'R' THEN 'Resource'
			WHEN 'V' THEN 'Non Qty Bearing'
			ELSE ''
		END,
	type_code,
	category ,
	inv_cost_method,
	
	method_desc = 
		CASE inv_cost_method
			WHEN 'S' THEN 'Standard'
			WHEN 'A' THEN 'Average'
			WHEN 'F' THEN 'FIFO'
			WHEN 'L' THEN 'LIFO'
			WHEN '1' THEN 'Weighted Average 1'
			WHEN '2' THEN 'Weighted Average 2'
			WHEN '3' THEN 'Weighted Average 3'
			WHEN '4' THEN 'Weighted Average 4'
			WHEN '5' THEN 'Weighted Average 5'
			WHEN '6' THEN 'Weighted Average 6'
			WHEN '7' THEN 'Weighted Average 7'
			WHEN '8' THEN 'Weighted Average 8'
			WHEN '9' THEN 'Weighted Average 9'
			ELSE ''
		END,
	lb_tracking,
	lb_tracking_desc = 
		CASE lb_tracking
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			ELSE ''
		END,
		
	qc_flag_desc =
		CASE qc_flag
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			ELSE ''
		END,
	taxable,
	taxable_desc =
		CASE taxable
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE ''
		END,	
	uom ,
	alt_uom = rpt_uom,
	allow_fractions_desc=
		CASE allow_fractions
			WHEN 0 THEN 'No'
			WHEN 1 THEN 'Yes'
			ELSE ''
		END,
	obsolete,
	obsolete_desc =
			CASE obsolete
			WHEN 0 THEN 'Not Obsolete'
			WHEN 1 THEN 'Do not allow reorder'
			ELSE ''
		END,
	void,
	void_desc=
			CASE void
			WHEN 'N' THEN 'No'
			WHEN 'V' THEN 'Yes'
			ELSE ''
		END,
	part_price.price_a ,
	comm_type ,
	vendor ,
	buyer ,
	freight_class ,
	weight_ea ,
	cycle_type ,
	account ,	
	date_entered = entered_date ,
   	tolerance_cd ,
	warranty_length ,
	pur_prod_flag_desc =
		CASE pur_prod_flag
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			ELSE ''
		END,

	x_part_price=part_price.price_a ,
	x_weight_ea=weight_ea ,
	x_date_entered = ((datediff(day, '01/01/1900', entered_date) + 693596)) + (datepart(hh,entered_date)*.01 + datepart(mi,entered_date)*.0001 + datepart(ss,entered_date)*.000001),
	x_warranty_length =warranty_length

 

from inv_master, part_price, glco
where inv_master.part_no = part_price.part_no
  and glco.home_currency = part_price.curr_key

 
GO
GRANT REFERENCES ON  [dbo].[aditm_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[aditm_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[aditm_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[aditm_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[aditm_vw] TO [public]
GO
