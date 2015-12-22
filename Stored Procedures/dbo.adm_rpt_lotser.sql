SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_lotser] @range varchar(8000) = '0=0',
@order varchar(1000) = ' lot_bin_stock.part_no'

 as

BEGIN
select @range = replace(@range,'"','''')
select @order = replace(@order,'"','''')

declare @sql varchar(8000)

select @sql = 'SELECT DISTINCT 
lot_bin_stock.part_no, 
lot_bin_stock.location, 
lot_bin_stock.bin_no, 
lot_bin_stock.lot_ser, 
lot_bin_stock.date_expires, 
lot_bin_stock.qty 
 FROM lot_bin_stock (nolock), locations l (nolock), region_vw r (nolock)
 WHERE l.location = lot_bin_stock.location and l.organization_id = r.org_id and ' +
  @range + '
 ORDER BY ' + @order

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_lotser] TO [public]
GO
