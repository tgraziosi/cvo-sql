SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- select * From cvo_NewRelChkLst_vw where model = '1016'

CREATE view [dbo].[cvo_NewRelChkLst_vw] as
-- tag - 013013 - add release date and po header note
-- tag - 031813 -- add drp info
-- tag - 5/3/2013 -- add po category
-- tag - 8/8/2013 -- show all po lines, even closed ones
/*
category_code	category_desc
FRAME	FRAME INVENTORY
FRAME-1	FRAME 1ST RELEASE AND PARTS
FRAME-2	FRAME 2ND RELEASE
FRAME-3	FRAME 3RD RELEASE
FRAME-SS	FRAME SAMPLE SETS
NONFRAME	NON-FRAME INVENTORY
NONINV	NON-INVENTORY
*/


select 

	ia.field_26 release_date,
	i.category Brand,
	ia.field_2 as Model,
	pa.vendor_no as Supplier,
	-- pr.curr_cost as Pricing,
	p.price_a as Pricing,
	cast(ia.field_17 as integer) Eye, 
	ia.field_6 Bridge, ia.field_8 Temple,
	ia.field_3 as Color,
	i.part_no,
	i.type_code,
	case when pa.status <> 'H' AND pa.user_category='FRAME-SS' then 'Y' 
		 else '' end as Approved,
	pa.user_category category,
	cat.category_desc,
	pa.po_key ,
	dateadd(dd, datediff(dd,0,pa.date_of_order), 0) date_of_order,
	pr.qty_ordered ,
	pr.qty_received ,
	ext_cost=curr_cost * pr.qty_ordered,
	qty_open = case when pr.qty_ordered-pr.qty_received < 0 then 0
					else pr.qty_ordered-pr.qty_received
				end,
	ext_cost_open = case when pr.qty_ordered - pr.qty_received < 0 then 0 
					     else curr_cost * (pr.qty_ordered-pr.qty_received)
				end,
	pr.confirm_date,
 	-- add new SA fields - 040513
	pr.departure_date,
	pr.inhouse_date,
	pr.location,
	case when isnull(pr.plrecd,0) = 1 then 'Y-L'
		when isnull(pa.expedite_flag,0) = 1 then 'Y-H' 
		else 'No' end as Pk_lst,
	pa.expedite_flag,
	brand_case = case when (select count(distinct location) from pur_list pp
				  inner join inv_master_add iia (nolock) on iia.part_no = pp.part_no 
				  where pp.po_no = pa.po_no and iia.field_2 = ia.field_2) > 1 and pr.location = '999'
				  then 'Y' else '' end
	, lead_time = ISNULL((SELECT MAX(lead_time) FROM inv_list il (NOLOCK) WHERE il.part_no = ia.part_no), 0)
	, pr.ship_via
	, pr.curr_cost
	, pa.curr_key
--	pr.brand_case
from inv_master_add ia (nolock)
inner join inv_master i (nolock) on i.part_no = ia.part_no
inner join part_price p (nolock) on p.part_no = ia.part_no
-- left outer join pur_list p (nolock) on ia.part_no = p.part_no
-- left outer join purchase_all pa (nolock) on pa.po_key = p.po_key
-- left outer join releases r (nolock) on p.po_no = r.po_no and p.line = r.po_line
left outer join
(
select p.po_no, p.part_no, p.status, r.confirm_date, isnull(r.departure_date, r.confirm_date) departure_date
, isnull(r.inhouse_date, r.confirm_date) inhouse_date, p.curr_cost
, sum(qty_ordered) qty_ordered, sum(qty_received) qty_received, p.location
, plrecd
, ship_via = CASE  p.ship_via_method WHEN 1 THEN 'BOAT'
						  WHEN 2 THEN 'AIR'
						  ELSE 'UNK' end
from 
pur_list p (nolock) 
inner join releases r (nolock) on r.po_no = p.po_no and r.po_line = p.line
where isnull(p.void,'N') <> 'V' 
-- 8/8/2013 - show all
-- and p.status <> 'C'
group by p.po_no, p.part_no, p.status, r.confirm_date,  r.departure_date
, r.inhouse_date, p.curr_cost, p.location, p.plrecd, p.ship_via_method
) pr on pr.part_no = ia.part_no
left outer join purchase_all pa (nolock) on pa.po_key = pr.po_no
left outer join po_usrcateg cat (nolock) on pa.user_category = cat.category_code
-- and i.type_code in ('FRAME','SUN')
-- and ia.field_26 between '20130730' and '20131231'







GO
GRANT REFERENCES ON  [dbo].[cvo_NewRelChkLst_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_NewRelChkLst_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_NewRelChkLst_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_NewRelChkLst_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_NewRelChkLst_vw] TO [public]
GO
