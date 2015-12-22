SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_critical] @bdate datetime, @edate datetime,
                 @loc varchar(10),  @pn varchar(30),  @vend varchar(10),
                 @type varchar(10), @cat varchar(10),
                 @status char(1)    AS 


  declare @stat1 char(1), 
          @stat2 char(1),
          @sbdate char(8),      
          @sedate char(8)       

  select @sbdate = Convert( char(8), @bdate, 112 )      
  select @sedate = Convert( char(8), @edate, 112 )      

  select @stat1='A', @stat2='V'
  if @status='P' begin
     select @stat1='N'
  end
  if @status='M' begin
     select @stat2='M'
  end

  CREATE TABLE #tcritical (
     location      varchar(10),
     part_no       varchar(30),
     description   varchar(255) NULL,
     demand_date   datetime,
     source        char(1),
     source_no     varchar(20),
     qty           decimal(20,8),
     uom           char(2)     NULL,   
     vendor        varchar(10) NULL,
     vend_name     varchar(40) NULL
)  

  INSERT #tcritical
  SELECT r.location,   
         r.part_no,   
         i.description,   
         r.demand_date,   
         r.source,   
         r.source_no,   
         r.qty,   
         i.uom,   
         CASE WHEN r.vendor is null THEN i.vendor
              ELSE r.vendor END,
         null  
    FROM resource_demand r
    left outer join inv_master i (nolock) on ( r.part_no = i.part_no) and
	 ( @type = '%' OR  
           i.type_code like @type ) AND  
         ( i.status >= @stat1 AND  
           i.status <= @stat2 ) AND  i.status <> 'R' AND
         ( @cat = '%' OR  
           i.category like @cat )    
   WHERE ( r.qty > 0 ) AND  
         ( ( Convert( char(8), r.demand_date, 112 ) >= @sbdate ) AND         
           ( Convert( char(8), r.demand_date, 112 ) <= @sedate ) ) AND       
         ( @loc = '%' OR  
           r.location like @loc ) AND  
         ( @pn = '%' OR  
           r.part_no like @pn )
         
   UPDATE #tcritical SET vend_name=v.vendor_name
   FROM   adm_vend_all v
   WHERE  v.vendor_code=#tcritical.vendor

   SELECT
     location    , part_no       ,
     description , demand_date   ,
     source      , source_no     ,
     qty         , uom           ,   
     vendor      , vend_name     ,
     @bdate      , @edate        ,
     @loc        , @pn           ,  
     @vend       , @type         , 
     @cat        , @status
   FROM #tcritical
   ORDER BY location, vendor, part_no, demand_date

GO
GRANT EXECUTE ON  [dbo].[fs_rpt_critical] TO [public]
GO
