SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Tine Graziosi - CVO
-- Create date: 11/27/2012
-- Description:	Rolling Active Doors by Ship-to, Month/Year
-- update - added st and rx sales breakdown
-- update - 2/15/2013 - add sales returns fields
-- update - 06/10/2013 - fix duplicate records due to yyyymmdd grouping
-- update - 10/29/2013 - per EL, assign territory to the Door's account
-- update - 11/21/2013 - shift lookback months by one to fix r12 figures
-- =============================================
-- exec [dbo].[CVO_rad_brand_sp]
-- select * from cvo.dbo.cvo_rad_brand order by customer, ship_to, yyyymmdd
-- select * from cvo_rad_brand where door = 0
-- select sum(netsales) from cvo_csbm_shipto c
	--inner join armaster ar on c.customer_code = ar.customer_code and c.ship_to_code = ar.ship_to_code
	--and c.territory_code = ar.territory_code
-- select 
--customer, ship_to, 
--sum(netsales) from cvo_rad_brand where territory = 20201 and year = 2013 group by customer, ship_to
--select customer, c.ship_to, door, sum(anet) from cvo_csbm_shipto c
--inner join armaster ar (nolock) on c.customer = ar.customer_code and c.ship_to = ar.ship_to_code
--inner join cvo_armaster_all ca (nolock) on c.customer = ca.customer_code and c.ship_to = ca.ship_to
--where territory_code = 20201 and year = 2013 group by c.customer, c.ship_to, door

--select customer_code, ship_to_code, territory_code from armaster 
--where customer_code in ('028230','030774')
-- select * From tempdb.dbo.#rad

-- select sum(areturns), sum(aret_rx), sum(aret_st), sum(aret_rx)+sum(aret_st) from cvo_rad_brand

-- exec cvo_rad_brand_sp
-- select * from cvo_rad_brand where [year] = 2012 and territory is null
/*

 select distinct yyyymmdd From cvo_rad_brand  order by yyyymmdd
  select * From #rad_det where customer_code like '%11012' order by yyyymmdd
  
   select sum(asales), sum(areturns), sum(asales_rx), sum(asales_st) from cvo_rad_brand
  --select distinct x_month, year, yyyymmdd from cvo_rad_brand order by yyyymmdd
  select  sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_customer_sales_by_month

  --where customer = '010098'
  select right(customer,5) customer, sum(asales), sum(areturns), sum(asales_rx), sum(asales_st), s
  
  select * From cvo_rad_brand where customer like '%11012%'
and yyyymmdd between '1/1/2012' and '1/31/2013' 
order by yyyymmdd
*/

CREATE PROCEDURE [dbo].[CVO_rad_brand_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF(OBJECT_ID('tempdb.dbo.#rad_det') is not null)  drop table #rad_det

create table #rad_det
-- add brand for brand r12 analysis
(brand varchar(10),
territory_code varchar(10),
customer_code varchar(10), 
ship_to_code varchar(10), 
door int, 
x_month int,
[year] int, 
netsales float,
asales float,
asales_rx float,
asales_st float,
areturns float,
aret_rx float,
aret_st float,
-- new 02/2013
areturns_s float,
aret_rx_s float,
aret_st_s float,
qsales int,
qsales_rx int,
qsales_st int,
qreturns int,
qret_rx int,
qret_st int,
qnet_frames int,
qnet_parts int,
qnet_cl int, -- closeout sales
anet_cl float
)

IF(OBJECT_ID('tempdb.dbo.#rad') is not null)  drop table #rad

create table #rad
(brand varchar(10),
territory_code varchar(10),
customer_code varchar(10), 
ship_to_code varchar(10), 
door int, 
date_opened datetime,
x_month int,
[year] int, 
yyyymmdd datetime,
netsales float,
asales float,
asales_rx float,
asales_st float,
areturns float,
aret_rx float,
aret_st float,
-- new 02/2013
areturns_s float,
aret_rx_s float,
aret_st_s float,
-- new 11/25/2013
qsales int,
qsales_rx int,
qsales_st int,
qreturns int,
qret_rx int,
qret_st int,
qnet_frames int,
qnet_parts int,
qnet_cl int,
anet_cl float,
rolling12net float,
	rolling12rx float,
	rolling12st float,
	rolling12ret float,
	-- new 02/13
	rolling12ret_s float,
rolling12RR float,
IsActiveDoor int default 1,
IsNew int default 0,
rolling12qnet int,
	rolling12qrx int,
	rolling12qst int,
	rolling12qret int,
	-- new 02/13
	rolling12qret_s int
)

-- set up the sales data so that every customer/month/year combo exists.

declare @yy int
declare @mm int

set @yy = 2008
set @mm = 1

while @yy <=  datepart(yy,getdate())
 begin
  while @mm < 13
   begin
	insert into #rad_det
	(brand, territory_code, customer_code, ship_to_code, door, x_month, [year], netsales, 
	asales, asales_rx, asales_st, areturns, aret_rx, aret_st, areturns_s, aret_rx_s, aret_st_s,
	qsales ,
qsales_rx ,
qsales_st ,
qreturns ,
qret_rx ,
qret_st ,
qnet_frames ,
qnet_parts,
qnet_cl,
anet_cl )
	
	select isnull(i.category,'') brand,
	ar.territory_code, 
	case when left(ar.customer_code,1) = '9' then
		'0'+ right(ltrim(rtrim(ar.customer_code)),5)
		else ar.customer_code end as  customer_code, 
	-- collapse non-door ship-to's into the main customer
	case when isnull(ca.door,0) =0 AND ca.ship_to <> '' then '' else ca.ship_to end as ship_to, 
	case when isnull(ca.door,0) =0 AND ca.ship_to <> '' then 1 else ca.door end as door, 
	--
	@mm, @yy, 
	isnull(anet, 0) as netsales,
	isnull(asales, 0) as asales,
	case WHEN isnull(xx.user_category,'ST') like 'RX%' then isnull(asales,0) ELSE 0 END AS asales_rx,
	case WHEN isnull(xx.user_category,'ST') not like 'RX%' then isnull(asales,0) ELSE 0 END AS asales_st,
	--isnull(asales_st, 0) as asales_st,
	--isnull(asales_rx, 0) as asales_rx,
	isnull(areturns, 0) as areturns,
	case WHEN isnull(xx.user_category,'ST') LIKE 'RX%' then isnull(areturns,0) ELSE 0 END AS aret_rx,
	case WHEN isnull(xx.user_category,'ST') not like 'rx%' then isnull(areturns,0) ELSE 0 END AS aret_st,
    --isnull(aret_rx, 0) as aret_rx,
	--isnull(aret_st, 0) as aret_st,
	-- new 0213
	case when isnull(xx.return_code,'') = '' then isnull(areturns, 0) else 0 end as areturns_s,
	case when isnull(xx.return_code,'') = '' and isnull(xx.user_category,'st') like 'rx%' 
	    then isnull(areturns, 0) else 0 end as aret_rx_s,
	case when isnull(xx.return_code,'') = '' and isnull(xx.user_category,'st') not like 'rx%' then isnull(areturns, 0) else 0 end as aret_st_s
	--isnull(aret_rx_s, 0) as aret_rx_s,
	--isnull(aret_st_s, 0) as aret_st_s
,
	isnull(qsales, 0) as qsales,
	case WHEN isnull(xx.user_category,'ST') like 'RX%' then isnull(qsales,0) ELSE 0 END AS qsales_rx,
	case WHEN isnull(xx.user_category,'ST') not like 'RX%' then isnull(qsales,0) ELSE 0 END AS qsales_st,	case when isnull(xx.return_code,'') = '' then isnull(qreturns, 0) else 0 end as qreturns,
	case when isnull(xx.return_code,'') = '' and isnull(xx.user_category,'st') like 'rx%' 
	    then isnull(qreturns, 0) else 0 end as qret_rx,
	case when isnull(xx.return_code,'') = '' and isnull(xx.user_category,'st') not like 'rx%' then isnull(qreturns, 0) else 0 end as qret_st,
	case when i.type_code in ('frame','sun') then qnet else 0 end as qnet_frames,
	case when i.type_code in ('parts') then qnet else 0 end as qnet_parts
	, case when xx.user_category like '%cl' then qnet else 0 end as qnet_cl
	, case when xx.user_category like '%cl' then anet else 0 end as anet_cl
	
	from cvo_armaster_all ca (nolock)
	inner join armaster ar (nolock) on ar.customer_code = ca.customer_code and ar.ship_to_code = ca.ship_to
	left outer join /*cvo_csbm_shipto*/ cvo_sbm_details xx (nolock) on
		   xx.customer = ca.customer_code and xx.ship_to=ca.ship_to
    left outer join inv_master i (nolock) on i.part_no = xx.part_no 
	where xx.x_month = @mm and xx.year = @yy
	and i.type_code in ('frame','sun','parts')
	
	set @mm = @mm + 1
	if @mm > datepart(mm,getdate()) and @yy = datepart(yy,getdate())
		break
	else
		continue
   end
   set @yy = @yy + 1
   set @mm = 1
end

create index [idx_rad_det] on #rad_det (brand,territory_code, customer_code, ship_to_code, netsales)

-- summarize

	insert into #rad
	
	(brand, territory_code, customer_code, ship_to_code, door, date_opened, x_month, [year], yyyymmdd, netsales, 
	asales, asales_rx, asales_st, areturns, aret_rx, aret_st, areturns_s, aret_rx_s, aret_st_s
	,qsales ,
qsales_rx ,
qsales_st ,
qreturns ,
qret_rx ,
qret_st ,
qnet_frames ,
qnet_parts,
qnet_cl,
anet_cl
)
	
	select rd.brand, ar.territory_code, rd.customer_code, rd.ship_to_code, rd.door,
	-- getdate() as date_opened,
	'1/1/1900' as date_opened, rd.x_month, rd.year, 
	cast ((cast(rd.x_month as varchar(2))+'/01/'+cast(rd.year as varchar(4))) as datetime) as yyyymmdd,
	sum(netsales) as netsales,
	sum(asales) as asales,
	sum(asales_rx) as asales_rx,
	sum(asales_st) as asales_st,
	sum(areturns) as areturns,
	sum(aret_rx) as aret_rx,
	sum(aret_st) as aret_st,
	sum(areturns_s) as areturns_s,
	sum(aret_rx_s) as aret_rx_s,
	sum(aret_st_S) as aret_st_s
	,
	sum(qsales) as qsales ,
    sum(qsales_rx) as qsales_rx,
    sum(qsales_st) as qsales_st ,
    sum(qreturns) as qreturns ,
    sum(qret_rx) as qret_rx ,
    sum(qret_st) as qret_st ,
    sum(qnet_frames) qnet_frames ,
    sum(qnet_parts) qnet_parts,
    sum(qnet_cl) qnet_cl,
    sum(anet_cl) anet_cl

	from #rad_det rd (nolock)
	inner join armaster ar (nolock) on ar.customer_code = rd.customer_code and ar.ship_to_code = rd.ship_to_code
	group by rd.brand, ar.territory_code, rd.customer_code, rd.ship_to_code, rd.door, x_month, [year]

	--select cast ((cast(6 as varchar(2))+'/01/'+cast(2013 as varchar(4))) as datetime)
-- update each customer/month/year record with the rolling 12 months net sales 

-- select * from #rad where customer_code = '040388' and x_month=11 and year=2011
-- select * From cvo_rad_brand where customer = '040388' and x_month=11 and year=2011

create index [idx_rad] on #rad
(brand, territory_code, customer_code, ship_to_code, yyyymmdd, netsales)


update rad set rolling12net = 
(select sum(isnull(rad12.netsales,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
and rad.brand = rad12.brand
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd
),
rolling12rx = 
(select sum(isnull(rad12.asales_rx,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
and rad.brand = rad12.brand
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12st = 
(select sum(isnull(rad12.asales_st,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
and rad.brand = rad12.brand
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12ret = 
(select sum(isnull(rad12.areturns,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
and rad.brand = rad12.brand
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12ret_s = 
(select sum(isnull(rad12.areturns_s,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
and rad.brand = rad12.brand
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd)
from #rad rad



update rad set rad.rolling12rr = 
	case rad.rolling12net when 0 then 
	 case rad.rolling12ret_s when 0 then 0 else 1 end
	else rad.rolling12ret_s / rad.rolling12net end
from #rad rad

--sum(isnull((case a.x_month when 1 then a.anet end), 0)) as jan,

-- set the active door flag based on the minimum sales $
-- at brand level active threshold is $250

update #rad set IsActiveDoor = 0
--where rad.rolling12net >= 2400.00
where #rad.rolling12net < 250.00 --2400.00

-- select * from #rad where date_opened = '1/1/1900'

-- fill in date opened for ship-to's 

update #rad set date_opened = rr.date_opened
from
#rad inner join
(select r.customer_code, r.brand, min(isnull(yyyymmdd,'1/1/1950')) date_opened from cvo_sbm_details c (nolock)
inner join inv_master i (nolock) on i.part_no = c.part_no
inner join
(select distinct customer_code, brand from #rad) r on c.customer = r.customer_code
and r.brand = i.category
where c.user_category like 'ST%' 
group by r.customer_code, r.brand) as rr 
on #rad.customer_code = rr.customer_code and #rad.brand = rr.brand

--update rad set
-- rad.date_opened = 
--  convert(datetime,dateadd(d,
--	isnull(ar.date_opened,dbo.adm_get_pltdate_f(ar.added_by_date))-711858,'1/1/1950'))
--from 
--#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
--where address_type = 0 

update #rad set IsNew = 1
where month(#rad.yyyymmdd) = month(#rad.date_opened) and year(#rad.yyyymmdd) = year(#rad.date_opened) 


-- select * from #rad where customer_code = '040388' and x_month=11 and year=2011

--update rad set rad.territory_code = isnull(ar.territory_code,'')
--from 
--#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
--and rad.ship_to_code = ar.ship_to_code
--where rad.territory_code <> ar.territory_code

-- where rad.date_opened is null

-- select * from cvo_rad_brand where customer = '011111' and ship_to = '' order by yyyymmdd

-- Create summary table by month

--update armaster set date_opened = dbo.adm_get_pltdate_f(added_by_date) where date_opened = 0

if (object_id('cvo.dbo.cvo_rad_brand') is not null)
	drop table cvo.dbo.cvo_rad_brand

if (object_id('cvo.dbo.cvo_rad_brand') is null)
 begin
 CREATE TABLE [dbo].[cvo_rad_brand]
(   brand varchar(10),
	territory varchar(10),
	[customer] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[ship_to] [varchar](10),
	door int,	
	date_opened datetime,
	[X_MONTH] [int] NULL,
	[year] [int] NULL,
	[yyyymmdd] [datetime],
	netsales float,
	asales float,
	asales_rx float,
	asales_st float,
	areturns float,
	aret_rx float,
	aret_st float,
	areturns_s float,
	aret_rx_s float,
	aret_st_s float,
	rolling12net float,
	rolling12rx float,
	rolling12st float,
	rolling12ret float,
	rolling12ret_s float,
	Rolling12RR float,
	IsActiveDoor int,
	IsNew int,
	qsales int,
	qsales_rx int,
	qsales_st int,
	qreturns int, 
	qret_rx int,
	qret_st int,
	qnet_frames int,
	qnet_parts int,
	qnet_cl int,
	anet_cl float
 ) ON [PRIMARY]

 GRANT SELECT ON [dbo].[cvo_rad_brand] TO [public]

 CREATE NONCLUSTERED INDEX [idx_cvo_rad_brand] ON [dbo].[cvo_rad_brand] 
 (
    brand asc,
    territory asc,
	[Customer] ASC,
	[ship_to] asc,
	[x_month] ASC,
	[year] ASC,
	[yyyymmdd] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end

/****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:28 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[cvo_rad_brand]') AND name = N'idx_yyyymmdd_rad')
DROP INDEX [idx_yyyymmdd_rad_brand] ON [dbo].[cvo_rad_brand] WITH ( ONLINE = OFF )

/****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:29 ******/
CREATE NONCLUSTERED INDEX [idx_yyyymmdd_rad] ON [dbo].[cvo_rad_brand] 
(
	[yyyymmdd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


insert cvo_rad_brand
(brand, territory, customer, ship_to, door, date_opened, x_month, [year], yyyymmdd,
 netsales, asales, asales_rx, asales_st, areturns, aret_rx, aret_st,
 areturns_s, aret_rx_s, aret_st_s, rolling12net, 
 rolling12rx, rolling12st, rolling12ret, rolling12ret_s, rolling12rr, IsActiveDoor, IsNew
 ,qsales,	qsales_rx , qsales_st , qreturns , qret_rx , qret_st,qnet_frames , qnet_parts 
, qnet_cl, anet_cl)
select 
brand, territory_code, customer_code, ship_to_code, door, date_opened, x_month, [year], yyyymmdd, netsales, 
asales, asales_rx, asales_st, areturns, aret_rx, aret_st,
areturns_s, aret_rx_s, aret_st_s, 
isnull(rolling12net,0), isnull(rolling12rx,0), isnull(rolling12st,0), 
isnull(rolling12ret,0), isnull(rolling12ret_s,0), isnull(rolling12rr,0), IsActiveDoor
, Isnew
, qsales,	qsales_rx , qsales_st , qreturns , qret_rx , qret_st,qnet_frames , qnet_parts 
, qnet_cl, anet_cl
from #rad

END

select * From cvo_rad_brand

GO
GRANT EXECUTE ON  [dbo].[CVO_rad_brand_sp] TO [public]
GO
