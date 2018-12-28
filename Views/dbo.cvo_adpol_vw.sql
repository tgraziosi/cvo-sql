SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO





-- select * From cvo_adpol_vw WHERE LOCATION = '001' AND STATUS_DESC = 'OPEN' and part_no like 'sp%'

CREATE VIEW [dbo].[cvo_adpol_vw] AS
-- tag - 013013 - add release date and po header note
-- tag - 031813 -- add drp info
-- tag - 5/3/2013 -- add po category
-- tag - 2/24/2015 - add line level PL flag
SELECT 
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
	qty_open = CASE WHEN qty_ordered-qty_received < 0 THEN 0
					ELSE qty_ordered-qty_received
				END,
	ext_cost_open = CASE WHEN qty_ordered-qty_received < 0 THEN 0 
					     ELSE curr_cost * (qty_ordered-qty_received)
					END,
	vend_sku ,
	account_no ,
	p.tax_code, 
	r.due_date,
	r.confirm_date,
 	-- add new SA fields - 040513
	ISNULL(r.departure_date, r.confirm_date) departure_date,
	ISNULL(r.inhouse_date, r.confirm_date) inhouse_date,
	-- 2/24/15 - 
	CASE WHEN ISNULL(p.plrecd,0) = 1 THEN 'Yes-L'
		 WHEN ISNULL(pa.expedite_flag,0) = 1 THEN 'Yes-H' 
		 ELSE 'No' END AS Pk_lst,
	-- case when pa.expedite_flag = 1 then 'Yes' else 'No' end as Pk_lst, -- 06/17/2013 for TB request
	p.status ,  
	status_desc =   
    CASE p.status + p.void    
		WHEN 'ON' THEN 'Open'  
		WHEN 'OO' THEN 'Open'
		WHEN 'HN' THEN 'Hold'  
		WHEN 'CV' THEN 'Void'  
		WHEN 'OV' THEN 'Void'
		WHEN 'CO' THEN 'Closed'
		WHEN 'CN' THEN 'Closed'  
	--   WHEN 'V' THEN 'Void'  pre-SCR 28228 KJC Jan 24 2002  
		ELSE ''  
    END,   
    '' AS [Shipping (Y/N)],
    '' AS [Vendor Comments],
    '' AS [CVO Ship Method],
	x_po_key=p.po_key ,
	x_line=p.line ,
	x_unit_cost=unit_cost,
	x_weight_ea=i.weight_ea,
	x_qty_ordered=qty_ordered ,
	x_qty_received=qty_received ,
	x_ext_cost=curr_cost * qty_ordered,

	-- tag - 031813 -- add drp info
	CAST(ISNULL(drp.e4_wu,0) AS VARCHAR(12)) e4_wu,
	CAST(ISNULL(drp.e12_wu,0) AS VARCHAR(12)) e12_wu,
	CAST(ISNULL(iav.in_stock,0) AS VARCHAR(12)) on_hand,
	CAST(CAST(ISNULL(iav.backorder,0) AS INTEGER) AS VARCHAR(12)) backorder,
	
	-- EL - 050914 -- Air or Ocean Delivery Method
	CASE WHEN p.ship_via_method IS NULL AND pa.ship_via_method IS NULL THEN 'NA'
		WHEN p.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method = 2 THEN 'Ocean'
		WHEN p.ship_via_method IS NULL AND pa.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method IS NULL AND pa.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IS NULL AND pa.ship_via_method = 2 THEN 'Ocean'
					ELSE 'XXXXXXXX' END AS Method,
	
	ISNULL(dbo.cvo_fn_rem_crlf(pa.note),'') AS note
	--isnull(ltrim(rtrim(left(pa.note,60))),'') note
	, i.type_code
    , i.upc_code -- 11/26/2018
FROM pur_list p (NOLOCK) 
INNER JOIN purchase_all pa (NOLOCK)
ON pa.po_key = p.po_key
LEFT JOIN releases r (NOLOCK)
ON p.po_key = r.po_key AND p.line = r.po_line
LEFT JOIN inv_master_add ia (NOLOCK) ON p.part_no = ia.part_no
LEFT JOIN inv_master i (NOLOCK) ON i.part_no = p.part_no
-- tag - 031813
LEFT OUTER JOIN dbo.cvo_item_avail_vw AS iav ON iav.location = p.location AND iav.part_no = p.part_no
LEFT OUTER JOIN
(SELECT part_no, location, e4_wu, e12_wu FROM dbo.f_cvo_calc_weekly_usage_coll('o',null))
 AS drp ON drp.location = p.location AND drp.part_no = p.part_no
--left join dpr_report drp (nolock) 
--on p.part_no = drp.part_no and p.location = drp.location
WHERE p.po_key = p.po_no AND pa.po_no = pa.po_key
AND r.po_key = r.po_no








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
