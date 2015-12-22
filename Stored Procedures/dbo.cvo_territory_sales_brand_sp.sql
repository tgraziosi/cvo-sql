SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_territory_sales_brand_sp]
@FromDate datetime, @ToDate datetime 
as
begin

-- exec cvo_territory_sales_brand_sp '1/1/2013', '8/7/2013'

IF(OBJECT_ID('tempdb.dbo.#tsr') is not null)  drop table #tsr

CREATE TABLE #tsr
(territory_code	varchar(8),
c_year int,
asales float,
areturns float,
qsales float,
qreturns float,
Region	varchar(3),
Brand varchar(10)
)

--declare @fromdate datetime, @todate datetime
--set @fromdate = '1/1/2013'
--set @todate = getdate()

declare @fromdateLY datetime, @todateLY datetime
set @fromdateLY = dateadd(year,-1,(dateadd(day,datediff(day,0,@fromdate),0)))
set @todateLY = dateadd(year,-1,(dateadd(day,datediff(day,0,@todate),0)))

-- select @fromdately,  @todately

insert into #tsr 
select 
ar.territory_code terr, 
sbm.c_year,
sum(asales) asales,
sum(areturns) areturns,
sum(qsales) qsales,
sum(qreturns) qreturns,
'' as region,
inv.category Brand
from
cvo_sbm_details sbm (nolock) 
inner join armaster ar (nolock) on ar.customer_code = sbm.customer  and ar.ship_to_code = sbm.ship_to
inner join inv_master inv (nolock) on inv.part_no =  sbm.part_no

Where 
((sbm.yyyymmdd between @fromdate and @todate) or (sbm.yyyymmdd between @fromdately and @todately))
and sbm.return_code = ''  -- sales and Rotate stock returns only
and inv.type_code in ('frame','sun')

group by
ar.territory_code, 
sbm.c_year,
inv.category 

update #tsr set region = dbo.calculate_region_fn(territory_code)

select * From #tsr

end

grant execute on [cvo_territory_sales_brand_sp] to public
GO
GRANT EXECUTE ON  [dbo].[cvo_territory_sales_brand_sp] TO [public]
GO
