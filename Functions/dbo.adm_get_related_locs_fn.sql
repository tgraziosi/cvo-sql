SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  FUNCTION [dbo].[adm_get_related_locs_fn]  (@module varchar(10), @org_id varchar(30), @sec_level int)
	RETURNS TABLE 
AS	
	RETURN ( SELECT location from locations_all (NOLOCK))
/*

	RETURN  (
  	    select a.location from (
        select location	from locations (nolock)
        join glco (nolock) on ib_flag = 0
        where lower(@module) not like '%-org' or lower(@module) like 'xfr%'
  		UNION
        select location
        from locations_all (nolock)
        where organization_id in (select detail_org_id from oorel_vw where controlling_org_id = @org_id)
          and  (((lower(@module) like 'soe%' or lower(@module) like 'po%' or lower(@module) like 'cm%'
			or lower(@module) like 'match%') 
          and lower(@module) not like '%-org')  or lower(@module) like 'xfr-f%')
  		UNION
        select location
        from locations_all (nolock)
        where organization_id in (select controlling_org_id from oorel_vw 
			join locations_all l on oorel_vw.detail_org_id = l.organization_id and l.location = substring(@org_id,5,20))
          and lower(@module) like 'xfr-t%'
        UNION
        select location from locations_all (nolock) where organization_id = @org_id and lower(@module) not like 'xfr-t%'
        UNION
        select l.location from locations_all l (nolock)
		join locations_all o on o.organization_id = l.organization_id and o.location = substring(@org_id,5,20) and lower(@module) like 'xfr-t%'
		) as a(location)
    join (select b.location from (
	select location
	from adm_po_locorgrel_vw (nolock) where related_org_id = @org_id and use_ind = 1 and loc_security_flag = 1 
          and ((io_use_po_ind = 1 and @sec_level > 0) or @org_id = organization_id) and (lower(@module) like 'po%' or lower(@module) like 'match%')
	UNION
	select location
	from adm_so_locorgrel_vw (nolock) where related_org_id = @org_id and use_ind = 1 and loc_security_flag = 1
	  and (lower(@module) like 'soe%' or lower(@module) like 'cm%')
	  and ((io_use_so_ind = 1 and @sec_level > 0) or @org_id = organization_id)
	UNION -- to loc search
	select l.location
    from adm_xfr_locorgrel_vw a (nolock) 
    join locations l (nolock) on l.organization_id = a.related_org_id
    where a.location = substring(@org_id,5,20) and a.loc_security_flag = 1 and lower(@module) like 'xfr-t%'
	  and ((a.io_use_xfer_ind = 1  and a.use_ind = 1  and @sec_level > 0) or a.related_org_id = a.organization_id)
	UNION -- from loc search
	select location
	from adm_xfr_locorgrel_vw (nolock) where related_org_id = @org_id and use_ind = 1 and loc_security_flag = 1 and lower(@module) like 'xfr-f%'
	  and ((io_use_xfer_ind = 1 and @sec_level > 0) or @org_id = organization_id)
	UNION
	select location
	from locations_all l (nolock)
	join dmco (nolock) on 1=1
	where (loc_security_flag = 0 or @sec_level = 99) and (@sec_level > 0 or @org_id = organization_id) 
	  or ((lower(@module) like 'po%' or lower(@module) like 'match%') and not exists (select 1 from adm_po_locorgrel_vw r (nolock) where related_org_id = @org_id and r.location = l.location)
	  and (isnull((select io_use_po_ind from adm_organization o (nolock)  
            where o.organization_id = @org_id),use_po_dflt_ind) = 1 and @sec_level > 0) )
	  or ((lower(@module) like 'soe%' or lower(@module) like 'cm%') and not exists (select 1 from adm_so_locorgrel_vw r (nolock) where related_org_id = @org_id and r.location = l.location)
	  and (isnull((select io_use_so_ind from adm_organization o (nolock) 
            where o.organization_id = @org_id),use_so_dflt_ind) = 1 and @sec_level > 0) )
	  or ((lower(@module) like 'xfr-f%') and not exists (select 1 from adm_xfr_locorgrel_vw r (nolock) where related_org_id = @org_id and r.location = l.location)
	  and (isnull((select io_use_xfer_ind from adm_organization o (nolock) 
            where o.organization_id = @org_id),use_xfr_dflt_ind) = 1 and @sec_level > 0) )
	) as b(location)) as b(location) on b.location = a.location
	)
*/
GO
GRANT REFERENCES ON  [dbo].[adm_get_related_locs_fn] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_get_related_locs_fn] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_get_related_locs_fn] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_get_related_locs_fn] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_get_related_locs_fn] TO [public]
GO
