
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE view [dbo].[cvo_ryg_summary_vw] as 
-- Use this for details for monthly list until you come up with somehting more 'elegant'

select distinct collection, style, 'All Colors' as color_desc, max(tl) tl, max(pom_date) pom_date 
from cvo_pom_tl_status c1 where style_pom_status = 'all' and active = 1 and tl <> ''
and 
(select count(distinct tl) from cvo_pom_tl_status c2 where c1.collection = c2.collection 
and c1.style = c2.style and c1.style_pom_status = c2.style_pom_status and c1.active = c2.active
and c2.tl <> '') = 1
group by collection, style, tl

union all
select distinct collection, style, color_desc, tl, pom_date from cvo_pom_tl_status c1 where style_pom_status = 'all' and active = 1 and c1.tl <> ''  
and (select count(distinct tl) from cvo_pom_tl_status c2 where c1.collection = c2.collection 
and c1.style = c2.style and c1.style_pom_status = c2.style_pom_status and c1.active = c2.active
and c2.tl <> '') >1
group by collection, style, color_desc, tl, pom_date

union all
select distinct collection, style, color_desc, tl, pom_date as pom_date
from cvo_pom_tl_status
where style_pom_status <> 'all' AND ACTIVE = 1 and tl <> ''

union all 
select distinct collection, style, 'PRE-2013 POM' as color_desc, tl, pom_date as pom_date
from cvo_pom_tl_status
where tl = '' AND ACTIVE = 1

--and tl<>'R'
--order by collection, style, color_desc





GO

GRANT SELECT ON  [dbo].[cvo_ryg_summary_vw] TO [public]
GO
