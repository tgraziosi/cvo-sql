SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_srecap] @range varchar(8000) = '0=0',
@order varchar(1000) = ' shippers.order_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)
CREATE TABLE #rpt_srecap (
	order_no int NULL ,
	order_ext int NULL ,
	ship_to_region varchar (10) NULL ,
	part_no varchar (30) NULL ,
	shipped decimal(18, 0) NULL ,
	price decimal(18, 0) NULL ,
	cust_code varchar (10) NULL ,
    ship_to_no varchar(10) NULL,
	customer_name varchar (40) NULL ,
	date_shipped datetime NOT NULL ,
	cr_shipped decimal(18, 0) NULL 
)



select @sql = '
insert into #rpt_srecap
SELECT distinct
shippers.order_no,    
shippers.order_ext,   
shippers.ship_to_region,   
shippers.part_no,   
shippers.shipped,   
shippers.price,   
shippers.cust_code,   
shippers.ship_to_no,
adm_cust_all.customer_name,   
shippers.date_shipped,   
shippers.cr_shipped  
FROM shippers (nolock), adm_cust_all (nolock), locations l (nolock), region_vw r (nolock)
WHERE ( shippers.cust_code = adm_cust_all.customer_code ) and 
      l.location = shippers.location and 
      l.organization_id = r.org_id and ' + @range + '
order by ' + @order
			
exec (@sql)

select @sql = 'select 
shippers.order_no,    
shippers.order_ext,   
shippers.ship_to_region,   
shippers.part_no,   
shippers.shipped,   
shippers.price,   
shippers.cust_code,   
shippers.customer_name,   
shippers.date_shipped,   
shippers.cr_shipped  
 from #rpt_srecap shippers order by ' + @order

exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_srecap] TO [public]
GO
