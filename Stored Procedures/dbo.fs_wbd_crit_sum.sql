SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_wbd_crit_sum] @edate datetime, @loc varchar( 5 ), @stat char( 1 )   AS


if @stat = '%'
BEGIN
  SELECT dbo.resource_demand.part_no,   
         min(dbo.resource_demand.demand_date),   
         min(dbo.inv_master.uom),
         sum(dbo.resource_demand.qty),   
         min(dbo.resource_demand.source),   
         min(dbo.resource_demand.source_no)  
    FROM dbo.resource_demand, dbo.inv_master  
   WHERE ( dbo.resource_demand.part_no = dbo.inv_master.part_no ) AND
         ( dbo.resource_demand.demand_date <= @edate ) AND  
         ( dbo.resource_demand.location = @loc ) AND  
         ( dbo.resource_demand.type like @stat ) AND  
         ( dbo.resource_demand.qty > 0 )   
GROUP BY dbo.resource_demand.part_no
ORDER BY dbo.resource_demand.part_no ASC
END

if @stat = 'M'
BEGIN
  SELECT dbo.resource_demand.part_no,   
         min(dbo.resource_demand.demand_date),   
         min(dbo.inv_master.uom),
         sum(dbo.resource_demand.qty),   
         min(dbo.resource_demand.source),   
         min(dbo.resource_demand.source_no)  
    FROM dbo.resource_demand, dbo.inv_master  
   WHERE ( dbo.resource_demand.part_no = dbo.inv_master.part_no ) AND
         ( dbo.resource_demand.demand_date <= @edate ) AND  
         ( dbo.resource_demand.location = @loc ) AND  
         ( dbo.resource_demand.type <> 'R' ) AND  
         ( dbo.resource_demand.qty > 0 )   
GROUP BY dbo.resource_demand.part_no
ORDER BY dbo.resource_demand.part_no ASC   
END

if @stat = 'R'
BEGIN
  SELECT dbo.resource_demand.part_no,   
         min(dbo.resource_demand.demand_date),   
         min(dbo.inv_master.uom),
         sum(dbo.resource_demand.qty),   
         min(dbo.resource_demand.source),   
         min(dbo.resource_demand.source_no)  
    FROM dbo.resource_demand, dbo.inv_master  
   WHERE ( dbo.resource_demand.part_no = dbo.inv_master.part_no ) AND
         ( dbo.resource_demand.demand_date <= @edate ) AND  
         ( dbo.resource_demand.location = @loc ) AND  
         ( dbo.resource_demand.type = 'R' ) AND  
         ( dbo.resource_demand.qty > 0 )   
GROUP BY dbo.resource_demand.part_no
ORDER BY dbo.resource_demand.part_no ASC   
END

GO
GRANT EXECUTE ON  [dbo].[fs_wbd_crit_sum] TO [public]
GO
