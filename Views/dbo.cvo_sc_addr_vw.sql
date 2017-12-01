SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





---- select   reverse(left(reverse(rtrim(ltrim(slp.addr3+' '+slp.addr4+' '+slp.addr5))),
--   charindex(' ',reverse(rtrim(ltrim(slp.addr3+' '+slp.addr4+' '+slp.addr5))))-1))  from cvo_sc_addr_vw slp

CREATE view [dbo].[cvo_sc_addr_vw] 
as 


-- select * From cvo_sc_addr_vw where rsm_territory_code is null

select  
slp.salesperson_code,
slp.salesperson_name,
slp.addr1,
slp.addr2,
slp.addr3,
slp.addr4,
slp.addr5,
reverse(left(reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))),
charindex(' ',reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))))-1)) postal_code,
slp.addr_sort2 slp_email,
slp.phone_1 phone,
isnull(x.ship_via,'NONE')  ship_via,
cast( isnull(slp.territory_code,'') as varchar(8) ) territory_code, 
user_name = case when x.status =1 then x.user_name else '' end, 
security_code = case when x.status = 1 then x.security_code else '' end,
email_address = case when x.status = 1 then x.email_address else '' end, 
slp.salesperson_type,
slp.sales_mgr_code,
rsm.salesperson_name sales_mgr_name,
rsm.addr_sort2 sales_mgr_email,
CASE WHEN ISNULL(rsm.territory_code,'') = '' THEN ISNULL(slp.sales_mgr_code,'900') ELSE rsm.territory_code END AS rsm_territory_code,
dbo.calculate_region_fn(slp.territory_code) region,
l.location, -- 10/5/2017
ar.customer_code,
ar.ship_via_code

from arsalesp slp (nolock)
left outer join cvo_territoryxref x (nolock) on x.territory_code = slp.territory_code 
	and x.salesperson_code = slp.salesperson_code
LEFT OUTER JOIN arsalesp rsm (NOLOCK)
	ON rsm.salesperson_code = slp.sales_mgr_code
-- 10/5/2017
LEFT OUTER JOIN locations l ON l.addr5 = slp.addr_sort2 AND l.addr5 <> '' AND void <> 'V'
LEFT OUTER JOIN arcust ar ON ar.customer_code = slp.employee_code

where (isnull(x.salesperson_code,'') not in ('internal','ss'))
and (slp.status_type = 1) -- active
-- or (slp.status_type = 0 and x.status = 1))
-- and slp.salesperson_name not like '%default%'
-- order by slp.territory_code













GO

GRANT REFERENCES ON  [dbo].[cvo_sc_addr_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sc_addr_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sc_addr_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sc_addr_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sc_addr_vw] TO [public]
GO
