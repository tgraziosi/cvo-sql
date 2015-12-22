SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[cvo_sls_by_bin_fp_vw] 
as 

-- select  * from cvo_sls_by_bin_fp_vw where type_code = 'pattern'

select i.category brand, ia.field_2 style, i.part_no, i.type_code, ia.field_26 release_date, ia.field_28 pom_date, 
style_pom.style_pom_date,
-- dbo.f_cvo_get_part_tl_status(i.part_no, getdate()) part_tl_status, 
bp.location, bp.bin_no, bp.[primary], isnull(lb.qty,0) qty_on_hand, 
isnull(sls.ytd_sales_qty,0) ytd_sales_qty
from inv_master i (nolock)
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no
-- left outer join inventory inv (nolock) on inv.part_no = i.part_no and inv.location = '001' -- ytd sales
left outer join tdc_bin_part_qty bp (nolock) on bp.part_no = i.part_no and bp.location = '001' -- bin assign
left outer join tdc_bin_master bm (nolock) on bp.bin_no = bm.bin_no and bp.location = bm.location
left outer join lot_bin_stock lb (nolock) on lb.part_no = bp.part_no and lb.bin_no = bp.bin_no and lb.location = '001' -- qoh
left outer join (select part_no, sum(qsales) ytd_sales_qty from cvo_sbm_details (nolock) where year = datepart(year, getdate())
	and location = '001' and iscl = 0 group by part_no) sls on sls.part_no = i.part_no
left outer join
( select collection, style, max(pom_date) style_pom_date, max(style_pom_status) style_pom_status from cvo_pom_tl_status  
	where active = 1 group by collection, style
 ) as style_pom on style_pom.collection = i.category and style_pom.style = ia.field_2 
where left(bm.bin_no,3) in (select distinct left(bin_no,3) from tdc_bin_master bm (nolock) where bm.group_code = 'pickarea' and usage_type_code = 'replenish' and bm.bin_no like 'f%')
-- order by bm.bin_no

GO
GRANT REFERENCES ON  [dbo].[cvo_sls_by_bin_fp_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sls_by_bin_fp_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sls_by_bin_fp_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sls_by_bin_fp_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sls_by_bin_fp_vw] TO [public]
GO
