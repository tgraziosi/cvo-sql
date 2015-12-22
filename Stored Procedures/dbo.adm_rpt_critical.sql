SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_critical] @range varchar(8000) = '0=0', 
@rstat varchar(255) = '< "R"', @order varchar(1000) = 'resource_demand.location'
as
begin
  select @range = replace(@range,'"','''')
  select @order = replace(@order,'"','''')
  select @rstat = replace(@rstat,'"','''')

  CREATE TABLE #rpt_critical ( 
    location varchar(10), 
    part_no varchar(30), 
    description varchar(255) NULL, 
    demand_date datetime, 
    source char(1), 
    source_no varchar(20), 
    qty float, 
    uom char(2) NULL, 
    vendor varchar(10) NULL,
    vend_name varchar(40) NULL,
    row_id int identity(1,1))

select @order = replace(@order,'resource_demand.vendor','vendor')

declare @sql varchar(8000)
select @sql = 'INSERT INTO  #rpt_critical(location, part_no, description, demand_date, source, source_no, qty, uom, vendor, vend_name)
SELECT distinct
resource_demand.location, 
resource_demand.part_no, 
inv_master.description, 
resource_demand.demand_date, 
resource_demand.source, 
resource_demand.source_no, 
resource_demand.qty, 
inv_master.uom, 
CASE WHEN resource_demand.vendor is null THEN inv_master.vendor ELSE resource_demand.vendor END vendor, 
null 
FROM resource_demand (nolock), inv_master (nolock), locations l (nolock), region_vw r (nolock)
WHERE (resource_demand.part_no = inv_master.part_no) and 
(resource_demand.qty > 0 ) and 
inv_master.status <> ''R'' and
l.location = resource_demand.location and
l.organization_id = r.org_id and
resource_demand.status ' + @rstat + ' and ' + @range + '
order by ' + @order
--print @sql
exec(@sql)

UPDATE  #rpt_critical
SET vend_name = adm_vend_all.vendor_name 
FROM adm_vend_all 
WHERE adm_vend_all.vendor_code =  vendor

exec ('select location, part_no, description, demand_date, source, source_no,
qty, uom, vendor, vend_name from #rpt_critical order by row_id')

end
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_critical] TO [public]
GO
