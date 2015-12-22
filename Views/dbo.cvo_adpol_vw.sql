SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- select * From cvo_adpol_vw

CREATE view [dbo].[cvo_adpol_vw] as
-- tag - 013013 - add release date and po header note
-- tag - 031813 -- add drp info
-- tag - 5/3/2013 -- add po category
-- tag - 2/24/2015 - add line level PL flag
select 
	p.po_key ,
	pa.user_category category,
	pa.date_of_order,
	pa.vendor_no,
	p.line ,
	p.location ,
	p.part_no ,
	i.description,
	ia.field_26 release_date,
	item_type=
		CASE type
			WHEN 'P' THEN 'Purchase Item'
			WHEN 'M' THEN 'Miscellaneous'
			ELSE ''
		END, 
	unit_measure,
	unit_cost,
	pa.curr_key,
	curr_cost,
	i.weight_ea,
	qty_ordered ,
	qty_received ,
	ext_cost=curr_cost * qty_ordered,
	qty_open = case when qty_ordered-qty_received < 0 then 0
					else qty_ordered-qty_received
				end,
	ext_cost_open = case when qty_ordered-qty_received < 0 then 0 
					     else curr_cost * (qty_ordered-qty_received)
					end,
	vend_sku ,
	account_no ,
	p.tax_code, 
	r.due_date,
	r.confirm_date,
 	-- add new SA fields - 040513
	isnull(r.departure_date, r.confirm_date) departure_date,
	isnull(r.inhouse_date, r.confirm_date) inhouse_date,
	-- 2/24/15 - 
	case when isnull(p.plrecd,0) = 1 then 'Yes-L'
		 when isnull(pa.expedite_flag,0) = 1 then 'Yes-H' 
		 else 'No' end as Pk_lst,
	-- case when pa.expedite_flag = 1 then 'Yes' else 'No' end as Pk_lst, -- 06/17/2013 for TB request
	p.status ,  
	status_desc =   
    CASE p.status + p.void    
		WHEN 'ON' THEN 'Open'  
		WHEN 'HN' THEN 'Hold'  
		WHEN 'CV' THEN 'Void'  
		WHEN 'CN' THEN 'Closed'  
	--   WHEN 'V' THEN 'Void'  pre-SCR 28228 KJC Jan 24 2002  
		ELSE ''  
    END,   
    '' as [Shipping (Y/N)],
    '' as [Vendor Comments],
    '' as [CVO Ship Method],
	x_po_key=p.po_key ,
	x_line=p.line ,
	x_unit_cost=unit_cost,
	x_weight_ea=i.weight_ea,
	x_qty_ordered=qty_ordered ,
	x_qty_received=qty_received ,
	x_ext_cost=curr_cost * qty_ordered,

	-- tag - 031813 -- add drp info
	cast(isnull(drp.e4_wu,0) as varchar(10)) e4_wu,
	cast(isnull(drp.e12_wu,0) as varchar(10)) e12_wu,
	cast(isnull(drp.on_hand,0) as varchar(10)) on_hand,
	cast(isnull(drp.backorder,0) as varchar(10)) backorder,
	
	-- EL - 050914 -- Air or Ocean Delivery Method
	Case when p.ship_via_method IS NULL and pa.ship_via_method IS NULL THEN 'NA'
		WHEN p.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method = 2 THEN 'Ocean'
		WHEN p.ship_via_method IS NULL and pa.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method IS NULL and pa.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IS NULL and pa.ship_via_method = 2 THEN 'Ocean'
					ELSE 'XXXXXXXX' END AS Method,
	
	isnull(dbo.cvo_fn_rem_crlf(pa.note),'') as note
	--isnull(ltrim(rtrim(left(pa.note,60))),'') note
	, i.type_code

from pur_list p (nolock) 
inner join purchase_all pa (nolock)
on pa.po_key = p.po_key
left join releases r (nolock)
on p.po_key = r.po_key and p.line = r.po_line
left join inv_master_add ia (nolock) on p.part_no = ia.part_no
left join inv_master i (nolock) on i.part_no = p.part_no
-- tag - 031813
left join dpr_report drp (nolock) 
on p.part_no = drp.part_no and p.location = drp.location
where p.po_key = p.po_no and pa.po_no = pa.po_key
and r.po_key = r.po_no



GO
GRANT REFERENCES ON  [dbo].[cvo_adpol_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_adpol_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_adpol_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_adpol_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_adpol_vw] TO [public]
GO
