SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		ELABARBERA
-- Create date: 3/25/2013
-- Description:	Listing of Customers in Designation Codes that do not match appropriate Discount Price Types
-- EXEC CustDesigPriceType_SSRS_sp
-- =============================================
CREATE PROCEDURE [dbo].[CustDesigPriceType_SSRS_sp] 

AS
BEGIN

	SET NOCOUNT ON;

-- Get Designation Codes, into one field  (Where Designations date range is in report date range
IF(OBJECT_ID('tempdb.dbo.#CustDesig') is not null)
drop table dbo.#CustDesig
      ;WITH C AS 
            ( SELECT customer_code, code FROM cvo_cust_designation_codes (nolock) )
            select Distinct customer_code,
                              STUFF ( ( SELECT '; ' + code
                              FROM cvo_cust_designation_codes (nolock)
                              WHERE customer_code = C.customer_code
                              AND (END_DATE IS NULL or END_DATE >=getdate())
                              FOR XML PATH ('') ), 1, 1, ''  ) AS Desigs
      INTO #CustDesig
      FROM C
--  select * from #CustDesig

DECLARE @BBCODE  VARCHAR(5)
SET @BBCode = 'BB'+right(datepart(year,getdate()),2)

IF(OBJECT_ID('tempdb.dbo.#CustMatch') is not null)
drop table dbo.#CustMatch
select CASE WHEN STATUS_TYPE = '1' THEN 'Active' ELSE 'INActive' END as Status, Territory_code, t1.customer_code, address_name, addr2, case when addr3 like '%, __ %' then '' else addr3 end as addr3, city, state, postal_code as zip, price_code, tt.Rebate, t1.Code as PriCode, Desigs as AllDesigs,
CASE WHEN parent = T1.CUSTOMER_CODE THEN '' ELSE PARENT END AS 'PARENT', 
added_by_user_name, added_by_date, 
CASE WHEN modified_by_user_name BETWEEN '1' AND '900' THEN USER_NAME ELSE  ISNULL(modified_by_user_name,'') END AS modified_by_user_name,
modified_by_date 
INTO #CustMatch
from cvo_cust_designation_codes (nolock) t1
join cvo_designation_codes (nolock) tt on t1.code=tt.code
join armaster_all (nolock) t2 on t1.customer_code=t2.customer_code
join #CustDesig t3 on t1.customer_code=t3.customer_code
join artierrl (nolock) t4 on t1.customer_code = t4.rel_cust
LEFT OUTER JOIN CVO_CONTROL..SMUSERS T5 ON rtrim(T2.modified_by_user_name)=cast(T5.USER_ID as varchar(30))
Where T2.address_type=0 and tt.rebate='y' and  (END_DATE IS NULL or END_DATE >=getdate())
AND( (t1.CODE like '%opt%' and price_code<>'O')
  OR (t1.code like 'i-%' and price_code not in ('B','D','D1') ) 
  OR (t1.CODE in  ('VWEST','VILLA','FEC-M','FEC-A','BBG') and price_code not in ('D','D1') )
  OR (t1.CODE in  ('PRI','VT','OOGP','FEC-A','BBG') and price_code not in ('D','D1') )
  OR (t1.CODE like '%@BBCode%' and price_code <>'D' )
 )
 and primary_flag = 1
order by t1.customer_code, t1.code

delete from #CustMatch where PriCode like 'FEC%' and PARENT <> '000550'
-- SELECT * FROM #CustMatch

IF(OBJECT_ID('tempdb.dbo.#ContrCust') is not null)
drop table dbo.#ContrCust
select distinct customer_key into #ContrCust from c_quote where ship_to_no <> '*type*' and (date_expires is NULL or date_Expires >getdate())

SELECT DISTINCT t1.*, 
ISNULL(round((select sum(anet) from cvo_csbm_shipto t2 where  t1.customer_code=t2.customer and t2.year=datepart(year,getdate()-1)),2),'') LY_TYD_NetSales,
ISNULL(round((select sum(anet) from cvo_csbm_shipto t2 where  t1.customer_code=t2.customer and t2.yyyymmdd between dateadd(year,-1,getdate()) and getdate()),2),'') R12_NetSales,
case when customer_key is not null then 'Y' else '' end as 'CntrPrc',
(Select Top 1 Audit_date from cvo_cust_designation_codes_audit DCA where DCA.customer_code= t1.customer_code order by audit_date desc)as DesigAuditDate,
(Select Top 1 user_id from cvo_cust_designation_codes_audit DCA where DCA.customer_code= t1.customer_code order by audit_date desc)as DesigUserMod,
(select Top 1 field_from from CVOArmasterAudit CAA where caa.field_name ='Price_Code' and CAA.customer_code=t1.customer_code order by audit_date desc) as PriceFrom,
(select Top 1 field_to from CVOArmasterAudit CAA where caa.field_name ='Price_Code' and CAA.customer_code=t1.customer_code order by audit_date desc) as PriceTo,
(select Top 1 User_id from CVOArmasterAudit CAA where caa.field_name ='Price_Code' and CAA.customer_code=t1.customer_code order by audit_date desc) as PriceUserMod,
(select Top 1 audit_date from CVOArmasterAudit CAA where caa.field_name ='Price_Code' and CAA.customer_code=t1.customer_code order by audit_date desc) as PriceAuditDate

FROM #CustMatch t1
left join #ContrCust t3 on t1.customer_code=t3.customer_key
 ORDER BY PriCODE, PRICE_CODE

-- EXEC CustDesigPriceType_SSRS_sp

END

GO
