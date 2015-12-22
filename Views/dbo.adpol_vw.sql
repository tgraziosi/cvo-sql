SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adpol_vw] as

select 
	po_key ,
	line ,
	location ,
	part_no ,
	description,
	item_type=
		CASE type
			WHEN 'P' THEN 'Purchase Item'
			WHEN 'M' THEN 'Miscellaneous'
			ELSE ''
		END, 
	unit_measure,
	unit_cost,
	weight_ea,
	qty_ordered ,
	qty_received ,
	ext_cost=unit_cost * qty_ordered,
	vend_sku ,
	account_no ,
	tax_code, 

	x_po_key=po_key ,
	x_line=line ,
	x_unit_cost=unit_cost,
	x_weight_ea=weight_ea,
	x_qty_ordered=qty_ordered ,
	x_qty_received=qty_received ,
	x_ext_cost=unit_cost * qty_ordered


from pur_list

 
GO
GRANT REFERENCES ON  [dbo].[adpol_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adpol_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adpol_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adpol_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adpol_vw] TO [public]
GO
