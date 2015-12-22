SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[adm_orglinks_vw] AS

select v.vendor_code, c.customer_code, v.organization_id customer_org_id, v.related_org_id vendor_org_id
from adm_orgcustrel c (nolock), adm_orgvendrel v
where v.related_org_id = c.organization_id and v.use_ind = 1
and c.related_org_id = v.organization_id and c.use_ind = 1
GO
GRANT REFERENCES ON  [dbo].[adm_orglinks_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_orglinks_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_orglinks_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_orglinks_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_orglinks_vw] TO [public]
GO
