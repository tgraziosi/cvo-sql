SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_empty_bin_vw]
as
select  a.group_code, a.usage_type_code, a.location, a.bin_no, a.description,  
isnull(c.part_no,isnull(e.part_no,'Undefined')) as repl_part_no_assigned,
isnull(d.description,isnull(f.description,'')) as part_desc,
isnull(d.type_code,isnull(f.type_code,'')) as res_type,
isnull(d.obsolete,isnull(f.obsolete,'')) as obs_flg,
g.field_28 as pom_date
-- convert(varchar(12),isnull(g.field_28, isnull(g.field_28,'')),101) as POM_date
from tdc_bin_master a (nolock)
left outer join tdc_bin_replenishment c (nolock) on 
	(a.bin_no = c.bin_no and a.location = c.location) or c.bin_no is null
left outer join cvo_bin_replenishment_tbl e (nolock) on 
	(a.bin_no = e.bin_no) or e.bin_no is null
left outer join inv_master d (nolock) on -- regular replenishment tables
	(c.part_no = d.part_no) or d.part_no is null
left outer join inv_master f (nolock) on -- hb replenishment tables
	(e.part_no = f.part_no) or f.part_no is null
left outer join inv_master_add g (nolock) on -- regular
	(c.part_no = g.part_no) or g.part_no is null
left outer join inv_master_add h (nolock) on -- hb
	(f.part_no = h.part_no) or h.part_no is null
where not exists (select * from lot_bin_stock where location =a.location and bin_no = a.bin_no)
--order by a.group_code, a.usage_type_code, a.location, a.bin_no
GO
GRANT REFERENCES ON  [dbo].[cvo_empty_bin_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_empty_bin_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_empty_bin_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_empty_bin_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_empty_bin_vw] TO [public]
GO
