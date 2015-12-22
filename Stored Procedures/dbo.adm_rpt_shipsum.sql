SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_shipsum] @range varchar(8000) = '0=0',
@grouped varchar(1000) = 'NULL',
@order varchar(1000) = ' shippers.cust_code'
 as

BEGIN
select @range = replace(@range,'"','''')
select @grouped = replace(@grouped,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)


select @sql = '
 SELECT distinct
ship_to_region, 
cust_code, 
shipped, 
cr_shipped, 
price, 
customer_name, ' + @grouped + '
 FROM shippers (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock)
 WHERE shippers.cust_code = adm_cust_all.customer_code and 
      l.location = shippers.location and 
      l.organization_id = r.org_id and ' + @range + '
 ORDER BY ' + @order
			
print @sql
exec (@sql)

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_shipsum] TO [public]
GO
