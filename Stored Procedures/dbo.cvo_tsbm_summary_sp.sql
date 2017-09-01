SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Author: Tine Graziosi
-- 5/21/2013
-- Financial Reporting Supporting Reports 
-- 3) Sales and returns summary by region and territory
-- exec cvo_tsbm_summary_sp 2017,8 

CREATE procedure [dbo].[cvo_tsbm_summary_sp] (@year int, @month int)
as

--declare @year int, @month int
--set @year = 2013
--set @month = 6

select 
t.region, 
t.manager_name,
t.territory_code, 
salesperson_name = 
isnull((select top 1 salesperson_name 
from arsalesp sc (nolock) 
where sc.territory_code = t.territory_code
and sc.salesperson_type <> 1 and sc.status_type = 1
and sc.salesperson_name <> 'Marcella Smith'), t.territory_desc) ,
isnull(tsbm.c_month,datepart(mm,getdate())) x_month,
isnull(tsbm.c_year,datepart(yy,getdate())) year, -- fiscal dating
ytdty_netsales = sum(isnull(case when c_year = @year and c_month <= @month THEN tsbm.net_sales else 0 END,0)),
ytdty_bep =      sum(isnull(case when c_year = @year and c_month <= @month THEN tsbm.bep_sales else 0 END,0)),
ytdty_netret = sum(isnull(case when c_year = @year and c_month <= @month THEN tsbm.Net_ret else 0 END,0)),
ytdty_wtyret = sum(isnull(case when c_year = @year and c_month <= @month then tsbm.wty_ret else 0 END,0)),
ytdty_excret = sum(isnull(case when c_year = @year and c_month <= @month THEN tsbm.exc_ret else 0 end,0)),
ytdly_netsales = sum(isnull(case when c_year = @year-1 and c_month <= @month then tsbm.net_sales else 0 end,0)),
ytdly_bep    = sum(isnull(case when c_year = @year-1 and c_month <= @month then tsbm.bep_sales else 0 end,0)),
ytdly_netret = sum(isnull(case when c_year = @year-1 and c_month <= @month then tsbm.Net_ret else 0 end,0)),
ytdly_wtyret = sum(isnull(case when c_year = @year-1 and c_month <= @month then tsbm.wty_ret else 0 end,0)),
ytdly_excret = sum(isnull(case when c_year = @year-1 and c_month <= @month then tsbm.exc_ret else 0 end,0)),
NetReturns   = sum(isnull(tsbm.Net_ret,0)),
sum(isnull(tsbm.wty_ret ,0))  NetReturns_wty, 
sum(isnull(tsbm.exc_ret ,0))  NetReturns_Exc, 
sum(isnull(tsbm.net_sales,0)) NetSales,
sum(isnull(tsbm.bep_sales,0)) BEP_Sales

From 

(
SELECT arterr.territory_code,
arterr.territory_desc,
dbo.calculate_region_fn(arterr.territory_code) region, 
manager_name = 
isnull(
(select top 1 sm.salesperson_name from arsalesp sm where 
dbo.calculate_region_fn(sm.territory_code) = dbo.calculate_region_fn(arterr.territory_code)
and sm.salesperson_type = 1 and sm.status_type = 1), arterr.territory_desc)

FROM arterr (nolock)
) t

left outer join 
(
SELECT 
ar.territory_code,  c_year, c_month, 
SUM(CASE WHEN s.promo_id = 'bep' THEN s.asales ELSE 0 end) AS bep_sales,
SUM(CASE WHEN s.promo_id <> 'bep' THEN s.asales ELSE 0 end) AS net_sales,
SUM(CASE WHEN s.return_code = '' THEN s.areturns ELSE 0 end) AS Net_ret,
SUM(CASE WHEN s.return_code = 'exc' THEN s.areturns ELSE 0 end) AS exc_ret,
SUM(CASE WHEN s.return_code = 'wty' THEN s.areturns ELSE 0 end) AS wty_ret
from cvo_sbm_details (nolock) s
JOIN armaster ar (NOLOCK) 
ON ar.customer_code = s.customer AND ar.ship_to_code = s.ship_to
WHERE c_year <= 2017
GROUP BY ar.territory_code, s.c_year, s.c_month
) tsbm on tsbm.territory_code = t.territory_code

GROUP BY t.region,
         t.manager_name,
         t.territory_code,
		 t.territory_desc,
		ISNULL(tsbm.c_month,datepart(mm,getdate())),
		ISNULL(tsbm.c_year,datepart(yy,getdate())) -- fiscal dating

GO
GRANT EXECUTE ON  [dbo].[cvo_tsbm_summary_sp] TO [public]
GO
