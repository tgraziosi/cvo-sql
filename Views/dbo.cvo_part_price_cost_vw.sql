SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_part_price_cost_vw]
as 

select part_no,
max(ISNULL(frame_price,0)) frame_price,
max(ISNULL(front_price,0)) front_price,
max(ISNULL(temple_price,0)) temple_price,

max(ISNULL(frame_cost,0)) frame_cost,
max(ISNULL(front_cost,0)) front_cost,
max(ISNULL(temple_cost,0)) temple_cost,
max(ISNULL(cable_cost,0)) cable_cost,
MAX(bp.Last_price_upd_date) last_price_upd_date

from
(
select i.part_no,
case when i.type_code in ('frame','sun','chassis') then ISNULL(p.price_a,0) else 0 end as frame_price,
case when i.type_code in ('frame','sun','chassis') then ISNULL(ila.std_cost,0) else 0 end as frame_cost
,cast(round(case when iia.category_3 = 'temple-l' 
	then ISNULL(pp.price_a,0) else 0 end,2) as decimal(8,2)) 
	as temple_price
,cast(round(case when iia.category_3 = 'front' 
	then ISNULL(pp.price_a,0) else 0 end,2) as decimal(8,2)) 
	as Front_price
,cast(round(case when iia.category_3 = 'temple-l' and iia.part_no like '%ls%'
		then ISNULL(iil.std_cost,0) else 0 end,2) as decimal(8,2))
		 as temple_cost
,cast(round(case when iia.category_3 = 'temple-l' and iia.part_no like '%lc%'
		then ISNULL(iil.std_cost,0) else 0 end,2) as decimal(8,2))
		 as cable_cost
,cast(round(case when iia.category_3 = 'front' 
		then ISNULL(iil.std_cost,0) else 0 end,2) as decimal(8,2))
		 as front_cost
, p.last_system_upd_date Last_price_upd_date
from 
	-- assembly data
	inv_master i (nolock) 
	LEFT outer join inv_master_add ia (nolock) on ia.part_no = i.part_no
	LEFT OUTER  join part_price p (nolock) on p.part_no = i.part_no
	LEFT OUTER  join inv_list ila (nolock) on ila.part_no = i.part_no and ila.location = '001'
	-- get bom
	LEFT OUTER  join what_part bom (nolock) on bom.asm_no = i.part_no
	-- component data
	LEFT outer join inv_master ii (nolock) on ii.part_no = bom.part_no
	LEFT OUTER  join inv_master_add iia (nolock) on iia.part_no = ii.part_no
	LEFT OUTER  join part_price pp (nolock) on pp.part_no = ii.part_no
	LEFT OUTER  join inv_list iil (nolock) on iil.part_no = bom.part_no and iil.location = '001'
	
	where 1=1
	and i.void = 'N'
	AND I.TYPE_code in ('frame','sun')
	-- and exists ( select 1 from what_part where asm_no = i.part_no)
	and ISNULL(ii.void,'n') = 'n' 
	and ISNULL(ii.type_code,'parts') in ('parts') 
	and ISNULL(bom.active,'a') = 'a'
) as bp

 -- where bp.part_no like 're%'
group by bp.part_no
-- order by bp.part_no



GO
GRANT REFERENCES ON  [dbo].[cvo_part_price_cost_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_part_price_cost_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_part_price_cost_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_part_price_cost_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_part_price_cost_vw] TO [public]
GO
