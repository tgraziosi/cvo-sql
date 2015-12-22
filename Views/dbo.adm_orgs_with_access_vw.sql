SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE view [dbo].[adm_orgs_with_access_vw]
AS
select case when organization_id = spid.org_id then 1 else 0 end curr_org_ind,  
    organization_id    
    from
	(
	SELECT 'SOME', organization_id FROM Organization_all
UNION
    select 'SOME', '')
    as t(access, organization_id)
    join (select dbo.sm_get_current_org_fn()) as spid(org_id) on 1=1
	where app_name()= 'Epicor Scheduler' or access = 'SOME'
GO
GRANT SELECT ON  [dbo].[adm_orgs_with_access_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_orgs_with_access_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_orgs_with_access_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_orgs_with_access_vw] TO [public]
GO
