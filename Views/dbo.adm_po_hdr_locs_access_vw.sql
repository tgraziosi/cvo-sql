SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[adm_po_hdr_locs_access_vw]
AS
select t.curr_org_ind, t.organization_id, t.location
from
    (select distinct isnull(r.create_ind,d.create_po_dflt_ind) create_ind, a.curr_org_ind, a.organization_id,
      a.location, isnull(io_create_po_ind,d.create_po_dflt_ind), isnull(spid.org_id,'')
    from adm_locs_with_access_vw a
    join dmco d (nolock) on 1 = 1
    join (select dbo.sm_get_current_org_fn()) as spid(org_id) on 1=1
	left outer join adm_organization o (nolock) on o.organization_id = spid.org_id
    left outer join adm_po_locorgrel_vw r (nolock) on  r.related_org_id = spid.org_id and a.location = r.location)
    as t(create_ind, curr_org_ind, organization_id, location, io_create_po_ind, user_org_id)
    where t.organization_id <> ''
GO
GRANT SELECT ON  [dbo].[adm_po_hdr_locs_access_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_po_hdr_locs_access_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_po_hdr_locs_access_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_po_hdr_locs_access_vw] TO [public]
GO
