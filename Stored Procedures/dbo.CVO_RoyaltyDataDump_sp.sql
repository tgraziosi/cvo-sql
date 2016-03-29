
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		elabarbera
-- Create date: 7/1/2013
-- Description:	Royalty Data Export
-- exec CVO_RoyaltyDataDump_sp '7/1/2013','7/31/2013'
-- =============================================
CREATE PROCEDURE [dbo].[CVO_RoyaltyDataDump_sp] 

@dfrom datetime,
@dto datetime

AS
BEGIN
	SET NOCOUNT ON;

-- exec cvo_royaltydatadump_sp '1/1/2016','2/29/2016'


--declare @dfrom datetime
--declare @dto datetime
declare @Gfrom int
declare @Gto int
--SET @DFrom = '2/1/2013'
--SET @DTo = '2/28/2013'
	SElect @DTo=dateadd(second,-1,@DTo)
	SElect @DTo=dateadd(day,1,@DTo)
select @Gfrom = dbo.adm_get_pltdate_f(@dfrom)

SElect @Gto = dbo.adm_get_pltdate_f(@dto)

IF(OBJECT_ID('tempdb.dbo.#Data') is not null)  drop table #Data
select order_no ,
       order_ext ,
       Invoice ,
       line_no ,
       part_no ,
       promo_id ,
       promo_level ,
       cust_type ,
       cust_code ,
       customer_name ,
       region ,
       territory ,
       ar_territory ,
       salesperson ,
       order_type ,
       date_shipped ,
       date_applied ,
       doc_type ,
       product_group ,
       product_type ,
       product_style ,
       product_gender ,
       Obsolete ,
       dom_intl ,
       country_code ,
       state_code ,
       units_sold ,
       list_price ,
       net_amt ,
       discount_amount ,
       DISCOUNT_PCT ,
       return_code ,
       cust_po ,
       x_date_shipped,
case when list_price=0 then 100 else (100-((100*NET_amt)/List_price)) END as  DiscPerc,
datepart(year,date_shipped)Yr,  datepart(quarter,date_shipped)Qtr,  datepart(month,date_shipped)Mth 
into #Data 
FROM cvo_royalties_vw 
WHERE product_type in ('frame','sun') 
AND date_shipped between @Dfrom and @Dto
-- --
-- --
select product_group, product_style, product_type, product_gender, doc_type,
case when product_style in ('hope', 'faith', 'believe', 'dream', 'strength', 'courage') then 'Y' else '' end as Charitable, 
Country_code as Country, dom_intl, cust_type,
SUM(case when doc_type='invoice' THEN ISNULL(list_price,0) else 0 END) as  'ListSold',
SUM(CASE WHEN  DiscPerc >=80 THEN ISNULL(NET_AMT,0) ELSE 0 END) AS 'CL(Net80Pct)',
SUM(CASE WHEN  cust_code='045217' THEN ISNULL(NET_AMT,0) ELSE 0 END) AS 'CL(NetCust)',
SUM(CASE WHEN CUST_CODE = '045217' THEN ISNULL(UNITS_SOLD,0) ELSE 0 END) AS 'CL(UnitCust)',

SUM(CASE WHEN cust_code='045217' THEN ISNULL(discount_amount,0) ELSE 0 END) AS 'CL(DiscCust)',

Sum(ISNULL(discount_amount,0))  'Discounts',
	
SUM(CASE WHEN doc_type='invoice' and promo_id='BEP' THEN isnull(net_amt,0) ELSE 0 END) AS 'BEPsNetSold',
SUM(CASE WHEN doc_type='invoice' THEN isnull(net_amt,0) ELSE 0 END) AS 'Gross-NetSold',
SUM(CASE WHEN doc_type<>'invoice' THEN isnull(net_amt,0) ELSE 0 END) AS 'Returns',
SUM(CASE WHEN doc_type<>'invoice' and promo_id<>'BEP' THEN ISNULL(NET_AMT,0) ELSE 0 END) AS 'Returns-NoBEP',

SUM(CASE WHEN  doc_type='invoice' THEN ISNULL(UNITS_SOLD,0) ELSE 0 END) AS 'GrossUnits-NetSold',
SUM(CASE WHEN  doc_type='invoice' and dom_intl ='Intnl' THEN ISNULL(UNITS_SOLD,0) ELSE 0 END) AS 'IntlGrossUnits-NetSold',

SUM(CASE WHEN doc_type<>'invoice' and promo_id<>'BEP' THEN ISNULL(UNITS_SOLD,0) ELSE 0 END) AS 'RetUnits-NoBEP',
SUM(CASE WHEN doc_type<>'invoice' and promo_id<>'BEP' and dom_intl ='Intnl' THEN ISNULL(UNITS_SOLD,0) ELSE 0 END) AS 'IntlRetUnits-NoBEP',

SUM(ISNULL(UNITS_SOLD,0)) 'NetUnits',
SUM(CASE WHEN DOM_INTL='Intnl' THEN ISNULL(UNITS_SOLD,0)  ELSE 0 END) AS 'IntlNetUnits',
SUM(CASE WHEN doc_type='invoice' and cust_type='Distributor' THEN ISNULL(units_sold,0) ELSE 0 end) AS 'DistrGrossUnits-NetSold',
SUM(CASE WHEN doc_type<>'invoice' and promo_id<>'BEP' and cust_type='Distributor' THEN ISNULL(units_sold,0) ELSE 0 END) AS 'DistrRetUnits-NoBEP',
SUM(CASE WHEN cust_type='Distributor' THEN ISNULL(units_sold,0) ELSE 0 END) AS 'DistrNetUnits',
dateadd(day,-1,dateadd(second,1,@DTo)) as Mnt

from #Data t1
group by product_group, product_style, product_type, product_gender, Country_code, dom_intl, cust_type, doc_type
order by product_group, product_style, product_type, product_gender, Country_code, dom_intl, cust_type
END



GO
