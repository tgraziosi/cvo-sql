SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- SELECT * FROM dbo.cvo_sc_addr_vw AS sav
-- SELECT * fROM LOCATIONS WHERE LOCATION LIKE '0%'

CREATE view [dbo].[cvo_sc_addr_vw] 
as 

-- select * From cvo_sc_addr_vw where rsm_territory_code is null
SELECT sc.salesperson_code,
       sc.salesperson_name,
       sc.addr1,
       sc.addr2,
       sc.addr3,
       sc.addr4,
       sc.addr5,
       sc.addr6,
       CASE WHEN ISNUMERIC(LEFT(sc.postal_code,1)) = 1 THEN sc.postal_code ELSE '' END postal_code,
       sc.slp_email,
       sc.phone,
       sc.ship_via,
       sc.territory_code,
       sc.user_name,
       sc.security_code,
       sc.email_address,
       sc.PresCouncil,
       sc.salesperson_type,
       sc.sales_mgr_code,
       sc.sales_mgr_name,
       sc.sales_mgr_email,
       sc.rsm_territory_code,
       sc.region,
       sc.location,
       sc.customer_code,
       sc.ship_via_code FROM 

(select  
slp.salesperson_code,
slp.salesperson_name,
slp.addr1,
slp.addr2,
slp.addr3,
slp.addr4,
slp.addr5,
slp.addr6,
-- '' postal_code,
CASE WHEN ISNULL(slp.addr6,'') > '' THEN
		reverse(left(reverse(rtrim(ltrim(isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')+' '+isnull(slp.addr6,'')))),
		CHARINDEX(' ',reverse(rtrim(ltrim(isnull(slp.addr4,'')+' '+isnull(slp.addr6,'')+' '+isnull(slp.addr6,'')))))-1))
	 WHEN ISNULL(slp.addr5,'') > '' THEN
		reverse(left(reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))),
		CHARINDEX(' ',reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))))-1))
	 WHEN ISNULL(slp.addr4,'') > '' THEN
		reverse(left(reverse(rtrim(ltrim(isnull(slp.addr2,'')+' '+isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')))),
		CHARINDEX(' ',reverse(rtrim(ltrim(isnull(slp.addr2,'')+' '+isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')))))-1))
	 WHEN ISNULL(slp.addr3,'') > '' THEN
		reverse(left(reverse(rtrim(ltrim(isnull(slp.addr1,'')+' '+isnull(slp.addr2,'')+' '+isnull(slp.addr3,'')))),
		CHARINDEX(' ',reverse(rtrim(ltrim(isnull(slp.addr1,'')+' '+isnull(slp.addr2,'')+' '+isnull(slp.addr3,'')))))-1))
	WHEN ISNULL(slp.addr2,'') > '' THEN
		reverse(left(reverse(rtrim(ltrim(isnull(slp.addr1,'')+' '+isnull(slp.addr2,'')))),
		CHARINDEX(' ',reverse(rtrim(ltrim(isnull(slp.addr1,'')+' '+isnull(slp.addr2,'')))))-1))
	ELSE ''
	END postal_code,

--reverse(left(reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))),
--charindex(' ',reverse(rtrim(ltrim(isnull(slp.addr3,'')+' '+isnull(slp.addr4,'')+' '+isnull(slp.addr5,'')))))-1)) postal_code,
slp.addr_sort2 slp_email,
slp.phone_1 phone,
isnull(x.ship_via,'NONE')  ship_via,
cast( isnull(slp.territory_code,'') as varchar(8) ) territory_code, 
case when x.status = 1 then x.user_name else '' END user_name, 
case when x.status = 1 then x.security_code else '' END security_code,
case when x.status = 1 then x.email_address else '' END email_address, 
CASE WHEN x.status = 1 THEN ISNULL(x.PresCouncil,'0') ELSE '0' END PresCouncil,
slp.salesperson_type,
slp.sales_mgr_code,
rsm.salesperson_name sales_mgr_name,
rsm.addr_sort2 sales_mgr_email,
CASE WHEN ISNULL(rsm.territory_code,'') = '' THEN ISNULL(slp.sales_mgr_code,'900') ELSE rsm.territory_code END AS rsm_territory_code,
dbo.calculate_region_fn(slp.territory_code) region,
l.location, -- 10/5/2017
ar.customer_code,
ar.ship_via_code

from DBO.arsalesp slp (nolock)
left outer join dbo.cvo_territoryxref x (nolock) on x.territory_code = slp.territory_code 
	and x.salesperson_code = slp.salesperson_code
LEFT OUTER JOIN dbo.arsalesp rsm (NOLOCK)
	ON rsm.salesperson_code = slp.sales_mgr_code
-- 10/5/2017
LEFT OUTER JOIN dbo.locations l ON l.addr5 = slp.addr_sort2 AND l.addr5 <> '' AND void <> 'V'
LEFT OUTER JOIN dbo.arcust ar ON ar.customer_code = slp.employee_code

where (isnull(x.salesperson_code,'') not in ('internal','ss'))
and (slp.status_type = 1) -- active
-- or (slp.status_type = 0 and x.status = 1))
-- and slp.salesperson_name not like '%default%'
-- order by slp.territory_code

UNION ALL

SELECT
'I-SALES' salesperson_code,
LA.NAME salesperson_name,
'I-SALES' addr1,
LA.ADDR1 addr2,
LA.ADDR2 addr3,
LA.ADDR3 addr4,
LA.ADDR4 addr5,
'' addr6,
LA.zip postal_code,
LA.addr_sort2 slp_email,
LA.PHONE phone,
'SAL'  ship_via,
'I-SALES' territory_code, 
'' user_name,
'0000' security_code,
'' email_address , 
'' PresCouncil,
0 salesperson_type,
'' sales_mgr_code,
'' sales_mgr_name,
'' sales_mgr_email,
''  rsm_territory_code,
'800'  region,
lA.location, -- 10/5/2017
'' customer_code,
'SAL' ship_via_code

FROM dbo.locations_all AS la WHERE location = '014'

UNION ALL

SELECT
'99'+LEFT(location,3) salesperson_code,
L.NAME salesperson_name,
'SALES BAG' addr1,
L.ADDR1 addr2,
L.ADDR2 addr3,
L.ADDR3 addr4,
L.ADDR4 addr5,
'' addr6,
L.zip postal_code,
L.addr_sort2 slp_email,
L.PHONE phone,
'SAL'  ship_via,
'99'+LEFT(location,3) territory_code, 
'' user_name,
'0000' security_code,
'' email_address , 
'' PresCouncil,
0 salesperson_type,
'' sales_mgr_code,
'' sales_mgr_name,
'' sales_mgr_email,
''  rsm_territory_code,
'800'  region,
l.location, -- 10/5/2017
'' customer_code,
'SAL' ship_via_code
FROM DBO.locations AS l WHERE LOCATION IN ('015-NSBAG','016-NSBAG','017-NSBAG')

) sc



















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
