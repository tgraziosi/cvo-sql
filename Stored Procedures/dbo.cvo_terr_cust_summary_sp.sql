SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[cvo_terr_cust_summary_sp] 
@Territory varchar(1000) = null, @Collection varchar(1000) = null, @startdate datetime, @enddate datetime

as
set nocount on 
begin
-- exec cvo_terr_cust_summary_sp null, null, '12/1/2013','12/01/2014'

create table #territory ( territory varchar(10) )
if @territory is null
begin
 insert into #territory(territory)
 select distinct territory_code from armaster 
end
else
begin
 insert into #territory(territory)
 select listitem from dbo.f_comma_list_to_table(@territory)
end

create table #collection ([collection] varchar(10))
if @collection is null
begin
 insert into #collection([collection])
 select distinct kys from category where void <> 'V'
end
else
begin
 insert into #collection( [collection] )
 select listitem from dbo.f_comma_list_to_table(@collection)
end

SELECT ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name customer_name, 
i.category collection, 
left(case when sbm.user_category = '' then 'ST' else sbm.user_category end,2) ord_type, 
sbm.c_year, sbm.c_month, 
sum(sbm.anet) anet
from armaster ar (nolock)
inner join #territory on #territory.territory = ar.territory_code
inner join cvo_sbm_details sbm (nolock) on ar.customer_code = sbm.customer and ar.ship_to_code = sbm.ship_to
inner join inv_master i (nolock) on i.part_no = sbm.part_no
inner join #collection on #collection.[collection] = i.category
inner join inv_master_add ia (nolock) on ia.part_no = i.part_no

where 1=1
and yyyymmdd between @startdate and @enddate

group by ar.territory_code, ar.customer_code, ar.ship_to_code, ar.address_name , 
i.category, left(case when sbm.user_category = '' then 'ST' else sbm.user_category end,2) , 
sbm.c_year, sbm.c_month

end
GO
GRANT EXECUTE ON  [dbo].[cvo_terr_cust_summary_sp] TO [public]
GO
