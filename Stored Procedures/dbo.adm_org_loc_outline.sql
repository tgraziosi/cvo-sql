SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_org_loc_outline] AS


declare @root_org varchar(30)
create table #orgs (parent_outline_num varchar(50),
parent_org_id varchar(30), child_org_id varchar(30), child_outline_num varchar(50),
child_region_flag char(1), protect int null, active int NULL)

create table #tree (this_id varchar(255), parent_id varchar(255),
label varchar(255), bold int, picture_index int, selected_picture_index int, ss_key varchar(255), children_ind int,
active int)

insert #orgs (parent_outline_num, parent_org_id, child_org_id, child_outline_num,
child_region_flag, protect, active)
select parent_outline_num, parent_org_id, child_org_id, child_outline_num, child_region_flag,
  0, active from
(SELECT '' parent_outline_num , '' parent_org_id ,organization_id child_org_id,'1' child_outline_num,
'1' child_region_flag, active_flag from Organization_all where outline_num = '1'
union
select '1','',organization_id, '',region_flag, active_flag
from Organization_all 
where outline_num <> '1' and organization_id not in (SELECT 	childs.organization_id child_org_id
FROM Organization_all childs
INNER JOIN  Organization_all  as parent ON childs.outline_num  like parent.outline_num + '.%'
WHERE parent.organization_id <> childs.organization_id 
AND CHARINDEX ( '.', SUBSTRING(	childs.outline_num, 
  CHARINDEX (	parent.outline_num+'.',childs.outline_num  )+len(parent.outline_num+'.') , 
  len(childs.outline_num) ) ) = 0  AND CHARINDEX ( '.',childs.outline_num  )<> 0)
union
SELECT 	parent.outline_num parent_outline_num, parent.organization_id parent_org_id,
  childs.organization_id child_org_id, childs.outline_num child_outline_num,
  childs.region_flag child_region_flag, childs.active_flag
FROM Organization_all childs
INNER JOIN  Organization_all  as parent ON childs.outline_num  like parent.outline_num + '.%'
WHERE parent.organization_id <> childs.organization_id 
AND CHARINDEX ( '.', SUBSTRING(	childs.outline_num, 
  CHARINDEX (	parent.outline_num+'.',childs.outline_num  )+len(parent.outline_num+'.') , 
  len(childs.outline_num) ) ) = 0  AND CHARINDEX ( '.',childs.outline_num  )<> 0 )
as a(parent_outline_num, parent_org_id, child_org_id, child_outline_num, child_region_flag, active)

update o
set protect = 1
from #orgs o
where not exists (select 1 from Organization p where p.organization_id = o.child_org_id)

insert #orgs (parent_outline_num, parent_org_id, child_org_id, child_outline_num,
child_region_flag, protect, active)
select o.child_outline_num, o.child_org_id, l.location, o.child_outline_num + '.' + l.location,'*',-1,
case when isnull(l.void,'N') = 'V' then 0 else 1 end
from locations_all l, #orgs o
where l.organization_id = o.child_org_id

update o
set protect = 1
from #orgs o
where not exists (select 1 from locations l where l.location = o.child_org_id)
and o.protect = -1

update #orgs
set protect = 0
where protect = -1

insert #tree
select 
case when t.child_outline_num = '' then t.child_org_id else t.child_outline_num end, t.parent_outline_num, 
case when child_region_flag = '*' then t.child_org_id else 
case when isnull(o.organization_name,'') = '' then t.child_org_id else o.organization_name end end, 
case when child_region_flag = '*' then 1 else 0 end, 
case when child_region_flag = '*' then 3 when t.child_outline_num = '' then 2 else 1 end, 1,
case when child_region_flag = '*' then t.child_org_id else '' end,
case when child_region_flag = '*' then 0 else 1 end,
active
from #orgs t
left outer join Organization_all o (nolock) on t.child_org_id = o.organization_id

select this_id, parent_id, label, bold, picture_index, picture_index, 
case when ss_key = '' then '' else 'S' end,ss_key, -1, children_ind, 
convert(char,abs(active-1)) + convert(char(10),len(parent_id))  + this_id sort_order
 from #tree
ORDER BY sort_order
GO
GRANT EXECUTE ON  [dbo].[adm_org_loc_outline] TO [public]
GO
