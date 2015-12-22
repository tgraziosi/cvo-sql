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

--declare @dfrom datetime
--declare @dto datetime
declare @Gfrom int
declare @Gto int
--SET @DFrom = '2/1/2013'
--SET @DTo = '2/28/2013'
	SET @DTo=dateadd(second,-1,@DTo)
	SET @DTo=dateadd(day,1,@DTo)
set @Gfrom = datediff(day,'1/1/1950',convert(datetime,convert(varchar( 8), (year(@dfrom) * 10000) + (month(@dfrom) * 100) + day(@dfrom)))  ) + 711858
set @Gto = datediff(day,'1/1/1950',convert(datetime,convert(varchar( 8), (year(@dto) * 10000) + (month(@dto) * 100) + day(@dto)))  ) + 711858
-- select @dfrom, @Dto, @Gfrom, @Gto
-- -- select * from #Data
IF(OBJECT_ID('tempdb.dbo.#Data') is not null)  
drop table #Data
select *,
case when list_price=0 then 100 else (100-((100*NET_amt)/List_price)) END as  DiscPerc,
datepart(year,date_shipped)Yr,  datepart(quarter,date_shipped)Qtr,  datepart(month,date_shipped)Mth 
into #Data from cvo_royalties_vw where product_type in ('frame','sun') and date_shipped between @Dfrom and @Dto
-- --
-- --
select distinct product_group, product_style, product_type, product_gender, doc_type,
case when product_style in ('hope', 'faith', 'believe', 'dream', 'strength', 'courage') then 'Y' else '' end as Charitable, Country_code as Country, dom_intl, cust_type,
case when doc_type='invoice' then sum(list_price) else 0 end as  'ListSold',

	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type AND DiscPerc >=80),0) 'CL(Net80Pct)',

	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type AND cust_code='045217'),0) 'CL(NetCust)',
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type AND cust_code='045217'),0) 'CL(UnitCust)',
	isnull((select sum(discount_amount) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type  AND cust_code='045217'),0) 'CL(DiscCust)',


	isnull((select sum(discount_amount) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type ),0) 'Discounts',
	
	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type='invoice' and promo_id='BEP'),0) 'BEPsNetSold',
	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type='invoice'),0) 'Gross-NetSold',
	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type<>'invoice'),0) 'Returns',
	isnull((select sum(net_amt) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type<>'invoice' and promo_id<>'BEP'),0) 'Returns-NoBEP',
	
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type='invoice'),0) 'GrossUnits-NetSold',
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type='invoice' and dom_intl ='Intnl'),0) 'IntlGrossUnits-NetSold',
	
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type<>'invoice' and promo_id<>'BEP'),0) 'RetUnits-NoBEP',
		isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type<>'invoice' and promo_id<>'BEP' and dom_intl ='Intnl'),0) 'IntlRetUnits-NoBEP',
		
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type),0) 'NetUnits',
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and dom_intl ='Intnl'),0) 'IntlNetUnits',

	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type='invoice' and cust_type='Distributor'),0) 'DistrGrossUnits-NetSold',
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and doc_type<>'invoice' and promo_id<>'BEP' and cust_type='Distributor'),0) 'DistrRetUnits-NoBEP',
	isnull((select sum(units_sold) from #data t11 where T1.product_group=T11.product_group AND T1.product_style=T11.product_style AND T1.product_type=T11.product_type AND T1.product_gender=T11.Product_gender AND T1.Country_code=T11.Country_code AND T1.dom_intl=T11.dom_intl AND T1.cust_type=T11.cust_type and t1.doc_type=t11.doc_type and cust_type='Distributor'),0) 'DistrNetUnits',
dateadd(day,-1,dateadd(second,1,@DTo)) as Mnt

from #Data t1
group by product_group, product_style, product_type, product_gender, Country_code, dom_intl, cust_type, doc_type
order by product_group, product_style, product_type, product_gender, Country_code, dom_intl, cust_type
END


GO
