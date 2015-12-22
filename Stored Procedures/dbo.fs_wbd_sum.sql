SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_wbd_sum] @bdate datetime, @edate datetime, @loc varchar( 5 )   AS

  SELECT dbo.resource_sch.part_no,   
         min(dbo.resource_sch.sch_date),   
         sum( dbo.resource_sch.qty ),   
         min(dbo.resource_sch.demand_date),   
         sum(dbo.resource_sch.demand_qty),   
         min(dbo.resource_sch.demand_source),   
         min(dbo.resource_sch.ilevel),   
         min(dbo.resource_sch.location),   
         min(dbo.resource_sch.source),   
         min(dbo.resource_sch.cnt),   
         min(dbo.resource_sch.demand_source_no),   
         min(dbo.resource_sch.source),
         min(dbo.resource_sch.sch_date)   
    FROM dbo.resource_sch  
   WHERE ( dbo.resource_sch.sch_date >= @bdate ) AND  
         ( dbo.resource_sch.sch_date <= @edate ) AND  
         dbo.resource_sch.location = @loc    
GROUP BY dbo.resource_sch.part_no
ORDER BY dbo.resource_sch.part_no

GO
GRANT EXECUTE ON  [dbo].[fs_wbd_sum] TO [public]
GO
