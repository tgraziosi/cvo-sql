SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_so_locorgrel_vw] as
select 
a.timestamp,
a.location,
a.related_org_id,
a.type_cd,
a.create_ind,
a.use_ind,
isnull(o.io_use_so_ind,d.use_so_dflt_ind) io_use_so_ind,
d.loc_security_flag,
isnull(l.organization_id ,'') organization_id
from adm_LocationOrganizationRel a (nolock)
join dmco d(nolock) on 1 = 1
left outer join adm_organization o (nolock) on a.related_org_id = o.organization_id
join locations_all l (nolock) on l.location = a.location
where a.type_cd = 'S' 
GO
GRANT REFERENCES ON  [dbo].[adm_so_locorgrel_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_so_locorgrel_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_so_locorgrel_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_so_locorgrel_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_so_locorgrel_vw] TO [public]
GO
