SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 8/20/2013
-- Description:	Sold To Sales & Tax by State / Month
-- exec AR_SalesByShipToState_SP '03/1/2015','03/31/2015'
-- =============================================
CREATE PROCEDURE [dbo].[AR_SalesByShipToState_SP] 
@DateFrom datetime,
@DateTo datetime
AS
BEGIN
	SET NOCOUNT ON;

--declare @DateFrom datetime
--declare @DateTo datetime
--set @DateFrom='10/1/2014'
--set @DateTo='12/31/2014'

declare @jdatefrom int, @jdateto int

SET @DateTo= dateadd(day,1,(dateadd(second,-1,@DateTo)))

set @jdatefrom =  dbo.adm_get_pltdate_F(@datefrom)
set @jdateto =  dbo.adm_get_pltdate_F(@dateto)

select t1.ship_to_country_cd country, 
c.description country_name,
CASE WHEN isnull(t1.ship_to_country_cd,'') = 'US' and 
	isnull(t1.ship_to_state,'') not in ('AK', 'AL', 'AR', 'AZ', 'CA', 'CO', 'CT', 'DC', 'DE', 'FL', 'GA', 'HI', 'IA', 'ID', 'IL', 'IN', 'KS', 'KY', 'LA', 'MA', 'MD', 'ME', 'MI', 'MN', 'MO', 'MS', 'MT', 'NC', 'ND', 'NE', 'NH', 'NJ', 'NM', 'NV', 'NY', 'OH', 'OK', 'OR', 'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VA', 'VT', 'WA', 'WI', 'WV', 'WY') 
	  THEN t1.[STATE]
	  ELSE isnull(t1.SHIP_TO_STATE,'') END 
	 AS SHIP_STATE, 
sum(amt_net) NET, 
sum(amt_tax) TAX, 
DATEPART(month, dbo.adm_format_pltdate_f(date_applied)) [Mth],
datename(month, dbo.adm_format_pltdate_f(date_applied)) [Month],
datename(year, dbo.adm_format_pltdate_f(date_applied))  [Yr],
'S' as Type
from cvo_invreg_vw T1
left outer join gl_country c on c.country_code = t1.ship_to_country_cd
WHERE DATE_APPLIED BETWEEN @jdatefrom and @jdateto
group by t1.ship_to_country_cd, c.description, t1.state, t1.ship_to_state, date_applied


UNION ALL 
SELECT DISTINCT t2.country_code as country, 
c.description country_name, 
T2.STATE as SHIP_STATE, 
0 as NET, 
case when trx_type = 2032 then -1*AMT_NET else AMT_NET end as TAX, 
DATEPART(month, dbo.adm_get_pltdate_f(date_applied)) [Mth],
datename(month,dbo.adm_get_pltdate_f(date_applied)) [Month],
datename(year, dbo.adm_get_pltdate_f(date_applied)) [Yr],
'N' AS Type
 FROM artrx t1(nolock)
JOIN ARMASTER T2 (NOLOCK) ON T1.CUSTOMER_CODE = T2.CUSTOMER_CODE AND T1.SHIP_TO_CODE=T2.SHIP_TO_CODE
left outer join gl_country c on c.country_code = t2.country_code
 WHERE t1.trx_type in ('2031','2032')  
AND t1.DOC_DESC NOT LIKE 'CONVERTED%'  
and DATE_APPLIED BETWEEN @jdatefrom and @jdateto
AND t1.doc_desc LIKE '%NONSALES%TAX%'  
order by t1.ship_to_country_cd


END


GO
