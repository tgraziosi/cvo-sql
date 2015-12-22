SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[cvo_region_sales_tyly] @asof datetime = null, @t varchar(1024) = NULL, @TopN INT = 100
as 

-- exec cvo_region_sales_tyly

set nocount on

declare @terr varchar(1024), @top int
declare @asofdate datetime, @asofdately datetime, @startdate datetime

if @asof is null select @asof = dateadd(d,-1, getdate())
SELECT @top = @topn
select @asofdate = datediff(d, 0, @asof)
select @asofdately = dateadd(yy, -1, @asof)
select @startdate = dateadd(yy,-2, datediff(d, 0, @asof))
-- select @asofdate, @asofdately, @startdate

select @terr = @t

CREATE TABLE #territory ([territory] VARCHAR(10))

if @terr is null
begin
	insert #territory
	select distinct territory_code from armaster where territory_code is not null and address_type <> 9
end
else
begin
	INSERT INTO #territory ([territory])
	SELECT  LISTITEM FROM dbo.f_comma_list_to_table(@terr)
end

;with cte as
(  select 
  dbo.calculate_region_fn(ar.territory_code) region
  , ar.territory_code
  , ar.customer_code
  , ar.ship_to_code
  , ar.address_name
  , ar.city
  , ar.state
  , ar.postal_code
  , ISNULL(ss.netsalesly,0) netsalesly
  , ISNULL(ss.netsalesty,0) netsalesty
  from 
  #territory t 
  inner join armaster ar (nolock) on t.territory = ar.territory_code
  left outer join
  (select top 100 percent
   sbm.customer
 , sbm.ship_to
 , Netsalesly = sum(case when isnull(sbm.yyyymmdd,@asofdate) <= @asofdately then isnull(sbm.anet,0) else 0 end)
 , netsalesty = sum(case when isnull(sbm.yyyymmdd,@asofdate) > @asofdately then isnull(sbm.anet,0) else 0 end) 
  from cvo_sbm_details sbm
  where sbm.yyyymmdd between @startdate and @asofdate
  group by sbm.customer, sbm.ship_to
  ) as ss on ar.customer_code = ss.customer and ar.ship_to_code = ss.ship_to
  where ar.address_type <> 9 
  
) 
SELECT 
  region
  , rank = row_number() OVER (Partition by region order by netsalesty-netsalesly desc )
  , territory_code
  , customer_code
  , ship_to_code
  , address_name
  , city
  , state
  , postal_code
  , netsalesly
  , netsalesty
  , (netsalesty-netsalesly) diff
   
  From cte
UNION ALL
SELECT 
  region
  , rank = row_number() OVER (Partition by region order by netsalesty-netsalesly asc )
  , territory_code
  , customer_code
  , ship_to_code
  , address_name
  , city
  , state
  , postal_code
  , netsalesly
  , netsalesty
  , (netsalesty-netsalesly) diff
   
  From cte
GO
