SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE View [dbo].[cvo_OverflowPutaway_vw] as

/* Overflow bins full - put inventory back to highbay location or to fwd pick bin */

-- select * From cvo_overflowputaway_vw

select 
lb.part_no, inv.description, ia.field_28 as pom_date, lb.qty ov_qty, lb.bin_no overflow_bin, 
case when (lb.qty <= (fp_max - fp_qoh)) then 'FP'
when lb.qty >=10 then 'HB' end as MoveTo,
lb.location, hb.bin_no highbay_bin, hb_qoh, hb_max,  
fp.bin_no fwdpick_bin, fp_qoh, fp_max 

from lot_bin_stock lb 

inner join /* overflow bins */
(select bin_no, location 
From tdc_bin_master where location = '001'  and usage_type_code = 'replenish' 
and group_code = 'overflow' and bin_no like 'H%'
) ofb on ofb.location = lb.location and ofb.bin_no = lb.bin_no

inner join inv_master inv on inv.part_no = lb.part_no
inner join inv_master_add ia on lb.part_no= ia.part_no 

left outer join /*highbay bins assigned - what to do if stock is in unassigned bin */
(
select bm.location, bm.bin_no, hbs.part_no, hbs.qty hb_qoh, bm.maximum_level hb_max,
rank() over (partition by hbs.part_no order by hbs.qty desc) as hbs_rank 
from tdc_bin_master bm
-- left outer join tdc_bin_part_qty bp on bp.bin_no = bm.bin_no and bp.location = bm.location
left outer join lot_bin_stock hbs on hbs.bin_no = bm.bin_no and hbs.location = bm.location 
where bm.bin_no like 'H%' and bm.usage_type_code = 'open' and bm.group_code = 'highbay'
and hbs.qty is not null and hbs.qty < bm.maximum_level 

) hb on lb.part_no = hb.part_no and lb.location = hb.location  and hb.hbs_rank = 1

left outer join /*fwd pick bins assigned*/
(
select bp.location, bp.bin_no, bp.part_no, fps.qty fp_qoh, bp.qty fp_max from tdc_bin_master bm
left outer  join tdc_bin_part_qty bp on bp.bin_no = bm.bin_no and bp.location = bm.location
left outer join lot_bin_stock fps on fps.part_no = bp.part_no and fps.bin_no = bp.bin_no and bp.location = fps.location 
where bm.bin_no like 'F%' and bm.usage_type_code = 'replenish' and bm.group_code = 'pickarea'
) fp on lb.part_no = fp.part_no and lb.location = fp.location

where 
/*(1=1) or */
(lb.qty >=10) or /*have a case that can be put back to high bay*/
(lb.qty <= (fp_max - fp_qoh)) /*there is room in the fwd pick bin*/



GO
GRANT REFERENCES ON  [dbo].[cvo_OverflowPutaway_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_OverflowPutaway_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_OverflowPutaway_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_OverflowPutaway_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_OverflowPutaway_vw] TO [public]
GO
