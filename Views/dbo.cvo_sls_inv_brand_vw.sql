SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--DECLARE @MONTH INT, @YEAR INT

--/* add this to the inventory snapshot job 
--if datepart(day,getdate()) = 1
--begin
--insert into cvo_inv_val_month
--select
--location, category, type_code, part_no, description, in_stock, lbs_qty,
--cvo_in_stock, ext_value, lbs_ext_value, cvo_ext_value, std_cost, std_ovhd_dolrs,
--std_util_dolrs, pns_qty, pns_value, qc_qty, qc_value, int_qty, int_value, obs,
--pom_date, bkordr_date, inv_acct_code, inv_ovhd_acct_code,
--inv_util_acct_code, dateadd(d,datediff(d,0,asofdate),-1) asofdate
--from cvo_inv_val_snapshot
--end
--*/

-- 8/16/2016 - remove 999 from inventory to include.  They want it as part of salesperson bags, as per DL
-- 2/16/2018 - add pogo Accessories
-- 10/2018 - add the three new NSBAG locations to SLP Bag Inventory

--SELECT @MONTH = 7
--SELECT @YEAR = 2013
CREATE view [dbo].[cvo_sls_inv_brand_vw] as 
SELECT 'Inventory' AS SRC,
case when category = 'UN' then 'ME'
    when category = 'izx' then 'IZOD'
    WHEN CATEGORY = 'CORP' THEN 'CVO'
    ELSE CATEGORY END AS BRAND, 
CASE WHEN INV.type_code IN ('frame','sun') THEN 'FRAME' ELSE INV.type_code end as TYPE_CODE, 
sum(isnull(cvo_in_stock,0)+isnull(pns_qty,0)+isnull(qc_qty,0)+isnull(int_qty,0))
 AS tot_qty,
sum(isnull(cvo_ext_value,0)+isnull(pns_value,0)+isnull(qc_value,0)+isnull(int_value,0)) as tot_value,
obs, location, datepart(month,asofdate) month, datepart(year,asofdate) year
from DBO.cvo_inv_val_month INV
where
 -- (location <= '200 - AAAA' or location >= '999')
 ( (location <= '200 - AAAA' or location > '999') and location NOT LIKE '%NSBAG' )
and type_code in ('frame','sun','ACC') 
--AND @MONTH = DATEPART(MONTH,ASOFDATE) AND @YEAR = DATEPART(YEAR,ASOFDATE)
group BY 
case when category = 'UN' then 'ME'
    when category = 'izx' then 'IZOD'
    WHEN CATEGORY = 'CORP' THEN 'CVO'
    ELSE CATEGORY END, 
	CASE WHEN INV.type_code IN ('frame','sun') THEN 'FRAME' ELSE INV.type_code END,
    obs, location, datepart(month,asofdate), datepart(year,asofdate)

UNION ALL

SELECT 'Sales' AS SRC,
case when category = 'UN' then 'ME'
    when category = 'izx' then 'IZOD'
    WHEN CATEGORY = 'CORP' THEN 'CVO'
    ELSE CATEGORY END AS BRAND, 
    -- 102113 - show ALL sales per DL request
case when I.TYPE_CODE in ('sun','FRAME') then 'FRAME' 
	 WHEN I.type_code = 'ACC' THEN 'ACC'
	 ELSE 'PARTS' END as type_code,
SUM(ISNULL(QNET,0)) AS TOT_QTY,
SUM(ISNULL(ANET,0)) AS TOT_VALUE,
CASE WHEN I.OBSOLETE = 0 THEN 'No'
     when i.obsolete = 1 then 'Yes' end as obs
, LOCATION,  sbm.c_month month, sbm.c_year year
FROM inv_master I (NOLOCK) INNER JOIN
cvo_sbm_details sbm (NOLOCK) ON I.PART_NO = SBM.PART_NO
WHERE 1=1
-- 102113 - show ALL sales per DL request
-- I.type_code IN ('FRAME','SUN','PARTS')
-- and (location <= '200 - AAAA' or location >= '999')
--AND SBM.C_MONTH = @MONTH AND SBM.C_YEAR = @YEAR
GROUP BY case when category = 'UN' then 'ME'
    when category = 'izx' then 'IZOD'
    WHEN CATEGORY = 'CORP' THEN 'CVO'
    ELSE CATEGORY END, 
    case when I.TYPE_CODE in ('sun','FRAME') then 'FRAME' 
		 WHEN I.type_code = 'ACC' THEN 'ACC' 
		 ELSE 'PARTS' end, 
    I.obsolete, sbm.location, sbm.c_month, sbm.c_year






GO
GRANT REFERENCES ON  [dbo].[cvo_sls_inv_brand_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sls_inv_brand_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sls_inv_brand_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sls_inv_brand_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sls_inv_brand_vw] TO [public]
GO
