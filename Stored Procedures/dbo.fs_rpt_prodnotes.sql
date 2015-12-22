SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_prodnotes] @i_no int, @i_ext int  AS 
BEGIN

  declare @x int, @y int
  CREATE TABLE #tpick (
         p_prod_no           int,   
         p_prod_ext          int,   
         p_status            char(1),   
         p_prod_date         datetime, 
         p_part_no           varchar(30),
         p_description       varchar(90) NULL,
         p_staging_area      varchar(12) NULL,
         p_project           varchar(10) NULL,
         p_sch_qty           decimal(20,8),  
         p_qty               decimal(20,8),  
         p_sch_date          datetime NULL,
         p_type              char(1) NULL,
         x_line_no           int, 
         x_seq_no            varchar(4),  
         x_part_no           varchar(30),   
         x_location          varchar(10),   
         x_planned           decimal(20,8),   
         x_picked            decimal(20,8),
         x_lb_tracking       char(1), 
         x_plan_pcs          decimal(20,8),  
         i_bin_no            varchar(12) NULL,   
         i_uom               char(2),   
         i_status            char(1),
         c_printed           char(1),   
         p_note              varchar(255) NULL,  
         x_note              varchar(255) NULL,   
         x_description       varchar(100) NULL,   
         note_flag           char(1) NULL ,
         w_note              varchar(255) NULL ,
         w_note2             varchar(255) NULL ,
         w_note3             varchar(255) NULL ,
         w_note4             varchar(255) NULL ,
         c_note              text NULL
)
  INSERT #tpick (
         p_prod_no          ,         p_prod_ext         ,
         p_status           ,         p_prod_date        ,
         p_part_no          ,         p_description      ,
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_qty              ,
         p_sch_date         ,         p_type             ,
         x_line_no          ,         x_seq_no           ,
         x_part_no          ,         x_location         ,
         x_planned          ,         x_picked           ,  
         x_lb_tracking      ,         x_plan_pcs         ,
         i_bin_no           , 
         i_uom              ,         i_status           ,
         c_printed          ,
         p_note             ,         x_note             ,
         x_description      ,         note_flag             )
  SELECT produce_all.prod_no          ,produce_all.prod_ext         ,
         produce_all.status           ,produce_all.prod_date        ,
         produce_all.part_no          ,null                         ,
         produce_all.staging_area     ,produce_all.project_key      ,
         produce_all.qty_scheduled    ,produce_all.qty              ,
         produce_all.sch_date         ,produce_all.prod_type        ,
         dbo.prod_list.line_no        ,dbo.prod_list.seq_no         ,
         dbo.prod_list.part_no        ,dbo.prod_list.location       ,
         dbo.prod_list.plan_qty       ,dbo.prod_list.used_qty       ,
         dbo.prod_list.lb_tracking    ,dbo.prod_list.plan_pcs       ,
         dbo.inventory.bin_no         ,
         dbo.inventory.uom            ,dbo.inventory.status         ,
         produce_all.status          ,
         produce_all.note             ,dbo.prod_list.note           ,
         dbo.inventory.description    ,'Y' 
    FROM produce_all,   
         dbo.prod_list,   
         dbo.inventory 
   WHERE ( produce_all.prod_no = dbo.prod_list.prod_no ) and  
         ( produce_all.prod_ext = dbo.prod_list.prod_ext ) and  
         ( dbo.prod_list.part_no = dbo.inventory.part_no ) and  
         ( dbo.prod_list.location = dbo.inventory.location ) and  
         ( produce_all.prod_no = @i_no ) AND  
         ( produce_all.prod_ext = @i_ext ) AND  
         ( dbo.prod_list.bench_stock < 'Y' ) AND  
         ( dbo.inventory.status < 'V' ) AND  
         produce_all.status >= 'N' AND  
         produce_all.status < 'R'   
ORDER BY dbo.prod_list.location ASC,   
         dbo.prod_list.line_no ASC   
  UPDATE #tpick
  SET    p_description=inv_master.description
  FROM   dbo.inv_master
  WHERE  p_part_no=inv_master.part_no
  UPDATE #tpick
  SET    p_sch_qty=p_qty
  WHERE  p_sch_qty=0
  UPDATE #tpick
  SET    p_sch_date=p_prod_date
  WHERE  p_sch_date is null
  UPDATE #tpick
  SET    note_flag='N'
  WHERE  x_note is null
  UPDATE #tpick
  SET    w_note=w.note, w_note2=w.note2, w_note3=w.note3, w_note4=w.note4
  FROM   dbo.what_part w
  WHERE  p_part_no = w.asm_no and x_part_no = w.part_no and
         x_seq_no = w.seq_no
  SELECT p_prod_no         ,          p_prod_ext         ,
         p_status           ,         p_sch_date         ,
         p_part_no          ,         p_description      ,
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_type             ,
         x_line_no          ,         x_seq_no           ,
         x_part_no          ,         x_location         ,
         x_planned          ,         x_picked           ,  
         x_lb_tracking      ,         x_plan_pcs         ,
         i_bin_no           , 
         i_uom              ,         i_status           ,
         c_printed          ,
         p_note             ,         x_note             ,
         x_description      ,         
         w_note             ,         w_note2            ,
         w_note3            ,         w_note4            ,
         c_note             
  FROM   #tpick  
  ORDER BY x_seq_no
END
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_prodnotes] TO [public]
GO
