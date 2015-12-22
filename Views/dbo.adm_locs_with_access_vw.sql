SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create view [dbo].[adm_locs_with_access_vw] as
  select distinct a.curr_org_ind, a.organization_id, l.location 
  from locations_all l (nolock)
  join adm_orgs_with_access_vw a (nolock) on a.organization_id = isnull(l.organization_id,'')

GO
GRANT REFERENCES ON  [dbo].[adm_locs_with_access_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_locs_with_access_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_locs_with_access_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_locs_with_access_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_locs_with_access_vw] TO [public]
GO
