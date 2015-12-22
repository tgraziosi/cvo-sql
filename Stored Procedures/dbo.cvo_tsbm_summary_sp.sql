SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Author: Tine Graziosi
-- 5/21/2013
-- Financial Reporting Supporting Reports 
-- 3) Sales and returns summary by region and territory
-- exec cvo_tsbm_summary_sp 2013, 8

CREATE procedure [dbo].[cvo_tsbm_summary_sp] (@year int, @month int)
as

--declare @year int, @month int
--set @year = 2013
--set @month = 6

select 
isnull(tsbm.c_month,datepart(mm,getdate())) x_month,
isnull(tsbm.c_year,datepart(yy,getdate())) year, -- fiscal dating
dbo.calculate_region_fn(t.territory_code) region, 
manager_name = 
isnull(
(select top 1 salesperson_name from arsalesp sm where 
dbo.calculate_region_fn(sm.territory_code) = dbo.calculate_region_fn(t.territory_code)
and sm.salesperson_type = 1 and sm.status_type = 1), t.territory_desc)
,t.territory_code, 
salesperson_name = 
isnull((select top 1 salesperson_name from arsalesp sc where 
sc.territory_code = t.territory_code
and sc.salesperson_type <> 1 and sc.status_type = 1
and sc.salesperson_name <> 'Marcella Smith'), t.territory_desc) 
,
ytdty_netsales = case when c_year = @year and c_month <= @month AND promo_id <> 'bep' then
	sum(isnull(asales,0)) else 0 end,
ytdty_bep = case when c_year = @year and c_month <= @month and promo_id = 'BEP' then
	sum(isnull(asales,0)) else 0 end,
ytdty_netret = case when c_year = @year and c_month <= @month and return_code = '' then
	sum(isnull(areturns,0)) else 0 end,
ytdty_wtyret = case when c_year = @year and c_month <= @month and return_code = 'WTY' then
	sum(isnull(areturns,0)) else 0 end,
ytdty_excret = case when c_year = @year and c_month <= @month and return_code = 'EXC' then
	sum(isnull(areturns,0)) else 0 end,
ytdly_netsales = case when c_year = @year-1 and c_month <= @month and promo_id <> 'bep' then
	sum(isnull(asales,0)) else 0 end,
ytdly_bep = case when c_year = @year-1 and c_month <= @month and promo_id = 'bep' then
	sum(isnull(asales,0)) else 0 end,
ytdly_netret = case when c_year = @year-1 and c_month <= @month and return_code = '' then
	sum(isnull(areturns,0)) else 0 end,
ytdly_wtyret = case when c_year = @year-1 and c_month <= @month and return_code = 'WTY' then
	sum(isnull(areturns,0)) else 0 end,
ytdly_excret = case when c_year = @year-1 and c_month <= @month and return_code = 'EXC' then
	sum(isnull(areturns,0)) else 0 end,
case when return_code = '' then sum(isnull(areturns,0)) else 0 end as  NetReturns,
case when return_code = 'WTY' then sum(isnull(areturns,0)) else 0 end as  NetReturns_wty, 
case when return_code = 'EXC' then sum(isnull(areturns,0)) else 0 end as  NetReturns_Exc, 
case when promo_id <> 'BEP' then sum(isnull(asales,0)) else 0 end as NetSales,
case when promo_id = 'BEP' then sum(isnull(asales,0)) else 0 end as BEP_Sales

From 
arterr t (nolock)
left outer join armaster ar (nolock) on ar.territory_code = t.territory_code
-- left outer join arsalesp s (nolock) on t.territory_code = s.territory_code
left outer join  cvo_sbm_details tsbm (nolock)
 on tsbm.customer = ar.customer_code and tsbm.ship_to = ar.ship_to_code
-- and s.territory_code <80000 
-- and s.territory_code is not null
where tsbm.c_year <= @year
-- and tsbm.promo_id <> 'BEP'
 -- exclude returns such as BEPs
 -- Don't include BEP sales either
group by c_year, c_month, t.territory_code, t.territory_desc, tsbm.promo_id, tsbm.return_code

GO
GRANT EXECUTE ON  [dbo].[cvo_tsbm_summary_sp] TO [public]
GO
