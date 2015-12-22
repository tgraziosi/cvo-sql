SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


create procedure [dbo].[adm_rpt_physval] @range varchar(8000) = '0=0',
@cost varchar(1000) = ' 0, ',
@order varchar(1000) = ' phy_batch, physical.location,part_no'
 as

BEGIN
select @range = replace(@range,'"','''')
select @cost = replace(@cost,'"','''')
select @order = replace(@order,'"','''')

CREATE table #rpt_physval ( 
  batch int, 
  location varchar(10), 
  part_no varchar(30), 
  orig_qty decimal(20,8), 
  qty decimal(20,8),  
  cost decimal(20,8), 
  description varchar(255) NULL,
  row_id int identity(1,1) ) 
  
declare @sql varchar(8000)

select @sql = 'INSERT INTO  #rpt_physval (batch, location, part_no, orig_qty, qty, cost, description)
  SELECT distinct
  physical.phy_batch, 
  physical.location, 
  physical.part_no, 
  sum(physical.orig_qty), 
  sum(physical.qty),  
  0, NULL 
  FROM  physical, locations l (nolock), region_vw r (nolock)
  WHERE l.location = physical.location and 
   l.organization_id = r.org_id and ' + @range + '
  GROUP BY physical.phy_batch, physical.location, physical.part_no 
  ORDER BY ' + @order

exec (@sql)

select @sql = 'UPDATE  #rpt_physval 
   SET cost =  ' + @cost + '
  description = inventory.description 
  FROM inventory 
   WHERE  #rpt_physval.part_no = inventory.part_no and  #rpt_physval.location = inventory.location'

exec (@sql)

select batch, location, part_no, orig_qty, qty, cost, description
from #rpt_physval
order by row_id

end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_physval] TO [public]
GO
