SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_rpt_pickprod] @i_no int, @i_ext int  AS 
BEGIN

  declare @x int, @y int
  CREATE TABLE #tpick (
         p_prod_no           int,   
         p_prod_ext          int,   
         p_status            char(1),   
         p_prod_date         datetime, 
         p_part_no           varchar(30) NULL,
         p_description       varchar(255) NULL,						-- mls 5/22/01
         p_staging_area      varchar(12) NULL,
         p_project           varchar(10) NULL,
         p_sch_qty           decimal(20,8),  
         p_qty               decimal(20,8),  
         p_sch_date          datetime NULL,
         p_type              char(1) NULL,
         x_line_no           int, 
         x_seq_no            char(4),
         x_part_type         char(1) NULL,  
         x_part_no           varchar(30),   
         x_location          varchar(10),   
         x_planned           decimal(20,8),   
         x_picked            decimal(20,8),
         x_lb_tracking       char(1), 
         x_plan_pcs          decimal(20,8),  
         i_bin_no            varchar(12) NULL,   
         i_uom               char(2),   
         i_in_stock          decimal(20,8),   
         i_commit_ed         decimal(20,8),   
         i_status            char(1) NULL,
         l_lot_ser           varchar(25) NULL,   
         l_bin_no            varchar(12) NULL,   
         l_qty               decimal(20,8) NULL,   
         l_uom_qty           decimal(20,8) NULL,   
         c_printed           char(1),   
         p_note              varchar(255) NULL,  
         x_note              varchar(255) NULL,   
         x_description       varchar(255) NULL,   					-- mls 5/22/01
         i_description       varchar(255) NULL ,					-- mls 5/22/01
         k_msg               varchar(255) NULL ,					-- mls 5/22/01
         k_flag              char(1) NOT NULL  ,
         x_pline             int,
         x_constrain         char(1)
)
  INSERT #tpick (
         p_prod_no          ,         p_prod_ext         ,
         p_status           ,         p_prod_date        ,
         p_part_no          ,         p_description      ,
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_qty              ,
         p_sch_date         ,         p_type             ,
         x_line_no          ,         x_seq_no           ,
         x_part_type        ,
         x_part_no          ,         x_location         ,
         x_planned          ,         x_picked           ,  
         x_lb_tracking      ,
         x_plan_pcs         ,         i_bin_no           , 
         i_uom              ,         i_in_stock         ,
         i_commit_ed        ,         i_status           ,
         l_lot_ser          ,
         l_bin_no           ,         l_qty              ,
         l_uom_qty          ,         c_printed          ,
         p_note             ,         x_note             ,
         x_description      ,         i_description      ,
         k_msg              ,         k_flag             ,
         x_pline            ,         x_constrain          )
  SELECT produce_all.prod_no          ,produce_all.prod_ext         ,
         produce_all.status           ,produce_all.prod_date        ,
         produce_all.part_no          ,produce_all.description      ,
         produce_all.staging_area     ,produce_all.project_key      ,
         produce_all.qty_scheduled    ,produce_all.qty              ,
         produce_all.sch_date         ,produce_all.prod_type        ,
         dbo.prod_list.line_no        ,dbo.prod_list.seq_no         ,
         dbo.prod_list.part_type      ,
         dbo.prod_list.part_no        ,dbo.prod_list.location       ,
         dbo.prod_list.plan_qty       ,dbo.prod_list.used_qty       ,
         IsNull(dbo.prod_list.lb_tracking,'N'),
         dbo.prod_list.plan_pcs       ,'N/A'                        ,
         'EA'                         ,0       ,
         0                            ,null         ,
         dbo.lot_bin_prod.lot_ser     ,
         dbo.lot_bin_prod.bin_no      ,dbo.lot_bin_prod.qty         ,
         dbo.lot_bin_prod.uom_qty     ,produce_all.status           ,
         produce_all.note             ,dbo.prod_list.note           ,
         dbo.prod_list.description    ,null    ,
         null                         ,'P'        ,
         dbo.prod_list.p_line         ,dbo.prod_list.constrain
    FROM produce_all 
         join dbo.prod_list (nolock) on ( produce_all.prod_no = dbo.prod_list.prod_no ) and  
         ( produce_all.prod_ext = dbo.prod_list.prod_ext ) and ( dbo.prod_list.bench_stock < 'Y' )
         left outer join dbo.lot_bin_prod (nolock) on ( dbo.prod_list.part_no = dbo.lot_bin_prod.part_no) and  
         ( dbo.prod_list.location = dbo.lot_bin_prod.location) and  
         ( dbo.prod_list.line_no = dbo.lot_bin_prod.line_no) and  
         ( dbo.prod_list.prod_no = dbo.lot_bin_prod.tran_no) and  
         ( dbo.prod_list.prod_ext = dbo.lot_bin_prod.tran_ext) 
   WHERE ( produce_all.prod_no = @i_no ) AND  
         ( produce_all.prod_ext = @i_ext ) AND  
         produce_all.status >= 'N' AND produce_all.status < 'R' AND dbo.prod_list.direction < 0
ORDER BY dbo.prod_list.location ASC,   
         dbo.prod_list.line_no ASC   

  UPDATE #tpick set 	i_description=i.description,
		 	i_bin_no=i.bin_no,
		 	i_commit_ed=i.commit_ed,
		 	i_uom=i.uom,
			i_in_stock=i.in_stock,
			i_status=i.status
  FROM inventory i
  WHERE i.part_no=#tpick.x_part_no and i.location=#tpick.x_location		

  UPDATE #tpick set i_status='P' where i_status is null

  UPDATE #tpick
  SET k_msg=i_uom+'  Bin: '+convert(char(12),l_bin_no)+'  Lot: '+l_lot_ser
  WHERE x_lb_tracking='Y' and p_type <> 'J' and p_type <> 'R'
  UPDATE #tpick
  SET    p_description=i.description
  FROM   dbo.inv_master i
  WHERE  p_part_no=i.part_no
  UPDATE #tpick
  SET    p_sch_qty=p_qty
  WHERE  p_sch_qty=0
  UPDATE #tpick
  SET    p_sch_date=p_prod_date
  WHERE  p_sch_date is null
  SELECT p_prod_no         ,          p_prod_ext         ,
         p_status           ,         p_sch_date         ,
         p_part_no          ,         substring(p_description,1,100)      ,			-- mls 5/22/01
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_type             ,
         0                  ,
         x_line_no          ,         x_seq_no           ,
         x_part_type        ,
         x_part_no          ,         x_location         ,
         x_planned          ,         x_picked           ,  
         x_lb_tracking      ,         x_plan_pcs         ,
         i_bin_no           , 
         i_uom              ,         i_in_stock         ,
         i_commit_ed        ,         i_status           ,
         l_lot_ser          ,
         l_bin_no           ,         l_qty              ,
         l_uom_qty          ,         c_printed          ,
         p_note             ,         x_note             ,
         substring(x_description,1,100)      ,         substring(i_description,1,100)      ,	-- mls 5/22/01
         substring(k_msg,1,200)              ,   						-- mls 5/22/01      
         case when p_type = 'R' then 0 else x_pline end  ,					-- mls 8/29/03 SCR 31816
         x_constrain,
         case when p_type = 'R' then x_pline else 0 end sort_order				-- mls 8/29/03 SCR 31816
  FROM   #tpick  
  ORDER BY x_pline, x_seq_no, l_bin_no
END
GO
GRANT EXECUTE ON  [dbo].[fs_rpt_pickprod] TO [public]
GO
