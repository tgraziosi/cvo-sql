SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Author: Tine Graziosi
-- 5/21/2013
-- Financial Reporting Supporting Reports 
-- 3) Sales and returns summary by Buying Group
-- exec cvo_bgsm_summary_sp 2013, 8

CREATE procedure [dbo].[cvo_bgsm_summary_sp] (@year int, @month int)
as

--declare @year int, @month int
--set @year = 2013
--set @month = 9

select 
isnull(bsbm.c_month,datepart(mm,getdate())) x_month,
isnull(bsbm.c_year,datepart(yy,getdate())) year, -- fiscal dating
isnull(ar.parent,'NON-BG') bg_code,
isnull(bg.customer_name,'') bg_name,
case when 
	bg.addr_sort1 = 'Buying Group' then 'BG'
	else 'NON-BG' end as Parent_Type, 
case when cust.territory_code  between '90900' and '90999' then 'Corp'
    when cust.territory_code between '80600' and '80699' then 'Corp'
    when cust.territory_code between '90600' and '90699' then 'Intl'
    else 'Cust' end as Cust_type,
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
armaster cust (nolock) 
left outer join  cvo_sbm_details bsbm (nolock)
 on bsbm.customer = cust.customer_code and bsbm.ship_to = cust.ship_to_code
left outer join arnarel ar (nolock) on ar.child = cust.customer_code
left outer join arcust bg (nolock) on bg.customer_code = ar.parent
and bsbm.c_year <= @year
group by c_year, c_month, ar.parent, bg.customer_name, bg.addr_sort1, cust.territory_code, bsbm.promo_id, bsbm.return_code

GO
GRANT EXECUTE ON  [dbo].[cvo_bgsm_summary_sp] TO [public]
GO
