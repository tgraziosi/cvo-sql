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
-- exec [dbo].[CVO_rad_shipto_sp]
-- select * from cvo.dbo.cvo_rad_shipto order by customer, ship_to, yyyymmdd
-- select * from cvo_rad_shipto where door = 0
-- select sum(netsales) from cvo_csbm_shipto c
	--inner join armaster ar on c.customer_code = ar.customer_code and c.ship_to_code = ar.ship_to_code
	--and c.territory_code = ar.territory_code
-- select 
--customer, ship_to, 
--sum(netsales) from cvo_rad_shipto where territory = 20201 and year = 2013 group by customer, ship_to
--select customer, c.ship_to, door, sum(anet) from cvo_csbm_shipto c
--inner join armaster ar (nolock) on c.customer = ar.customer_code and c.ship_to = ar.ship_to_code
--inner join cvo_armaster_all ca (nolock) on c.customer = ca.customer_code and c.ship_to = ca.ship_to
--where territory_code = 20201 and year = 2013 group by c.customer, c.ship_to, door

--select customer_code, ship_to_code, territory_code from armaster 
--where customer_code in ('028230','030774')
-- select * From tempdb.dbo.#rad

-- select sum(areturns), sum(aret_rx), sum(aret_st), sum(aret_rx)+sum(aret_st) from cvo_rad_shipto

-- exec cvo_rad_shipto_sp
-- select * from cvo_rad_shipto where [year] = 2012 and territory is null
/*

 select distinct yyyymmdd From cvo_rad_shipto  order by yyyymmdd
  select * From #rad_det where customer_code like '%11012' order by yyyymmdd
  
   select sum(asales), sum(areturns), sum(asales_rx), sum(asales_st) from cvo_rad_shipto
  --select distinct x_month, year, yyyymmdd from cvo_rad_shipto order by yyyymmdd
  select  sum(asales), sum(areturns), sum(qsales), sum(qreturns) from cvo_customer_sales_by_month

  --where customer = '010098'
  select right(customer,5) customer, sum(asales), sum(areturns), sum(asales_rx), sum(asales_st), s
  
  select * From cvo_rad_shipto where customer like '%11012%'
and yyyymmdd between '1/1/2012' and '1/31/2013' 
order by yyyymmdd
*/

CREATE PROCEDURE [dbo].[CVO_RAD_shipto_sp]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

IF(OBJECT_ID('tempdb.dbo.#rad_det') is not null)  drop table #rad_det

create table #rad_det
(territory_code varchar(10),
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
aret_st_s float)

IF(OBJECT_ID('tempdb.dbo.#rad') is not null)  drop table #rad

create table #rad
(territory_code varchar(10),
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
rolling12net float,
	rolling12rx float,
	rolling12st float,
	rolling12ret float,
	-- new 02/13
	rolling12ret_s float,
rolling12RR float,
IsActiveDoor int default 1)

-- set up the sales data so that every customer/month/year combo exists.

declare @yy int, @curyy int
declare @mm int, @curmm int

select @yy = 2008
select @mm = 1
select @curyy = datepart(yy,getdate())
select @curmm = datepart(mm,getdate())


while @yy <=  @curyy
 begin
  while @mm < 13
   begin
	insert into #rad_det
	(territory_code, customer_code, ship_to_code, door, x_month, [year], netsales, 
	asales, asales_rx, asales_st, areturns, aret_rx, aret_st, areturns_s, aret_rx_s, aret_st_s)
	
	select ar.territory_code, 
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
	
	from cvo_armaster_all ca (nolock)
	inner join armaster ar (nolock) on ar.customer_code = ca.customer_code and ar.ship_to_code = ca.ship_to
	left outer join /*cvo_csbm_shipto*/ cvo_sbm_details xx (nolock) on
		   xx.customer = ca.customer_code and xx.ship_to=ca.ship_to and 
		   xx.x_month = @mm and xx.year = @yy
	set @mm = @mm + 1
	if @mm > @curmm and @yy = @curyy
		break
	else
		continue
   end
   set @yy = @yy + 1
   set @mm = 1
end

create index [idx_rad_det] on #rad_det (territory_code, customer_code, ship_to_code, netsales)

-- summarize

	insert into #rad
	
	(territory_code, customer_code, ship_to_code, door, date_opened, x_month, [year], yyyymmdd, netsales, 
	asales, asales_rx, asales_st, areturns, aret_rx, aret_st, areturns_s, aret_rx_s, aret_st_s)
	
	select ar.territory_code, rd.customer_code, rd.ship_to_code, rd.door,
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
	from #rad_det rd (nolock)
	inner join armaster ar (nolock) on ar.customer_code = rd.customer_code and ar.ship_to_code = rd.ship_to_code
	group by ar.territory_code, rd.customer_code, rd.ship_to_code, rd.door, x_month, [year]

	--select cast ((cast(6 as varchar(2))+'/01/'+cast(2013 as varchar(4))) as datetime)
-- update each customer/month/year record with the rolling 12 months net sales 

-- select * from #rad where customer_code = '040388' and x_month=11 and year=2011
-- select * From cvo_rad_shipto where customer = '040388' and x_month=11 and year=2011

create index [idx_rad] on #rad
(territory_code, customer_code, ship_to_code, yyyymmdd, netsales)


update rad set rolling12net = 
(select sum(isnull(rad12.netsales,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd
),
rolling12rx = 
(select sum(isnull(rad12.asales_rx,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12st = 
(select sum(isnull(rad12.asales_st,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12ret = 
(select sum(isnull(rad12.areturns,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd),
rolling12ret_s = 
(select sum(isnull(rad12.areturns_s,0)) 
from #rad rad12 (nolock)
where rad.customer_code = rad12.customer_code and rad.ship_to_code = rad12.ship_to_code
and rad.territory_code = rad12.territory_code
	  and rad12.yyyymmdd between dateadd(mm,-11,rad.yyyymmdd) and rad.yyyymmdd)
from #rad rad

update rad set rad.rolling12rr = 
	case rad.rolling12rx + rad.rolling12st when 0 then 
	 case rad.rolling12ret_s when 0 then 0 else 1 end
	else rad.rolling12ret_s / (rad.rolling12st+rad.rolling12rx) end
from #rad rad

--sum(isnull((case a.x_month when 1 then a.anet end), 0)) as jan,

-- set the active door flag based on the minimum sales $

update #rad set IsActiveDoor = 0
--where rad.rolling12net >= 2400.00
where #rad.rolling12net < 2400.00

-- fill in date opened for ship-to's 

update rad set
 rad.date_opened = 
  convert(datetime,dateadd(d,
	isnull(ar.date_opened,dbo.adm_get_pltdate_f(ar.added_by_date))-711858,'1/1/1950'))
from 
#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
where address_type = 0 

-- select distinct date_opened, added_by_date, * from armaster where address_type = 0 and date_opened = 0
--update armaster set date_opened = dbo.adm_get_pltdate_f(added_by_date) 
--where customer_code = '045565' and date_opened = 0 and added_by_date = '03/23/2010'

-- select * from #rad where customer_code = '040388' and x_month=11 and year=2011

--update rad set rad.territory_code = isnull(ar.territory_code,'')
--from 
--#rad rad inner join armaster ar (nolock) on rad.customer_code = ar.customer_code
--and rad.ship_to_code = ar.ship_to_code
--where rad.territory_code <> ar.territory_code

-- where rad.date_opened is null

-- select * from cvo_rad_shipto where customer = '011111' and ship_to = '' order by yyyymmdd

-- Create summary table by month

--update armaster set date_opened = dbo.adm_get_pltdate_f(added_by_date) where date_opened = 0

if (object_id('cvo.dbo.cvo_rad_shipto') is not null)
	drop table cvo.dbo.cvo_rad_shipto

if (object_id('cvo.dbo.cvo_rad_shipto') is null)
 begin
 CREATE TABLE [dbo].[cvo_rad_shipto]
(
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
	IsActiveDoor int
 ) ON [PRIMARY]

 GRANT SELECT ON [dbo].[cvo_rad_shipto] TO [public]

 CREATE NONCLUSTERED INDEX [idx_cvo_rad_shipto] ON [dbo].[cvo_rad_shipto] 
 (
	territory asc,
	[Customer] ASC,
	[ship_to] asc,
	[x_month] ASC,
	[year] ASC,
	[yyyymmdd] asc
 ) WITH (SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF) ON [PRIMARY]
end

/****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:28 ******/
IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[cvo_rad_shipto]') AND name = N'idx_yyyymmdd_rad')
DROP INDEX [idx_yyyymmdd_rad] ON [dbo].[cvo_rad_shipto] WITH ( ONLINE = OFF )

/****** Object:  Index [idx_yyyymmdd_rad]    Script Date: 11/22/2013 15:27:29 ******/
CREATE NONCLUSTERED INDEX [idx_yyyymmdd_rad] ON [dbo].[cvo_rad_shipto] 
(
	[yyyymmdd] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


insert cvo_rad_shipto
(territory, customer, ship_to, door, date_opened, x_month, [year], yyyymmdd,
 netsales, asales, asales_rx, asales_st, areturns, aret_rx, aret_st,
 areturns_s, aret_rx_s, aret_st_s, rolling12net, 
 rolling12rx, rolling12st, rolling12ret, rolling12ret_s, rolling12rr, IsActiveDoor)
select 
territory_code, customer_code, ship_to_code, door, date_opened, x_month, [year], yyyymmdd, netsales, 
asales, asales_rx, asales_st, areturns, aret_rx, aret_st,
areturns_s, aret_rx_s, aret_st_s, 
isnull(rolling12net,0), isnull(rolling12rx,0), isnull(rolling12st,0), 
isnull(rolling12ret,0), isnull(rolling12ret_s,0), isnull(rolling12rr,0), IsActiveDoor
from #rad

END


GO
