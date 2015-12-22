SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_rpt_pickprod] @order int, @process_ctrl_num varchar(32) as
BEGIN
 declare @x int, @y int
 declare @max_stat char(1)
 declare @parent int, @row int
 declare @asmpart varchar(30) 
 declare @pos int, @prod varchar(10), @ext varchar(10)

 create table #torder (
 h_prod_no int,
 h_prod_ext int,
 h_status char(1),
 h_location varchar(10) null
 )
 create index #to1 on #torder(h_prod_no, h_prod_ext)


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
         p_location          varchar(10),
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
         x_constrain         char(1),
         x_note2             varchar(255) NULL,   
         x_note3             varchar(255) NULL,   
         x_note4             varchar(255) NULL,
	 row_id int identity(1,1)
)

create index #tp1 on #tpick(row_id)
create index #tp3 on #tpick(p_prod_no,p_prod_ext,x_line_no)


exec ('insert #torder 
select p.prod_no, p.prod_ext, p.status, p.location
from produce_all p
where status between ''P'' and ''Q'' and p.wopick_ctrl_num = ''' + @process_ctrl_num + '''')

INSERT #tpick (
         p_prod_no          ,         p_prod_ext         ,
         p_status           ,         p_prod_date        ,
         p_part_no          ,         p_description      ,
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_qty              ,
         p_sch_date         ,         p_type             ,
         p_location         ,
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
         x_pline            ,         x_constrain        ,
	 x_note2, x_note3, x_note4  )
SELECT produce.prod_no          ,produce.prod_ext         ,
         produce.status           ,produce.prod_date        ,
         produce.part_no          ,produce.description      ,
         produce.staging_area     ,produce.project_key      ,
         case when produce.qty_scheduled = 0 then produce.qty else produce.qty_scheduled end,
         produce.qty              ,
         isnull(produce.sch_date,produce.prod_date)         ,produce.prod_type        ,
         produce.location,
         prod_list.line_no        ,prod_list.seq_no         ,
         prod_list.part_type      ,
         prod_list.part_no        ,prod_list.location       ,
         prod_list.plan_qty       ,prod_list.used_qty       ,
         IsNull(prod_list.lb_tracking,'N'),
         prod_list.plan_pcs       ,'N/A'                        ,
         'EA'                         ,0       ,
         0                            ,'P'         ,
         lot_bin_prod.lot_ser     ,
         lot_bin_prod.bin_no      ,lot_bin_prod.qty         ,
         lot_bin_prod.uom_qty     ,produce.status           ,
         produce.note             ,isnull(prod_list.note,'')          ,
         prod_list.description    ,null    ,
         null                         ,'P'        ,
         prod_list.p_line         ,prod_list.constrain,
	 '','',''
FROM produce_all produce
join prod_list (nolock) on ( produce.prod_no = prod_list.prod_no ) and  
         ( produce.prod_ext = prod_list.prod_ext ) and ( prod_list.bench_stock < 'Y' ) AND prod_list.direction < 0
left outer join lot_bin_prod (nolock) on ( prod_list.part_no = lot_bin_prod.part_no) and  
         ( prod_list.location = lot_bin_prod.location) and  
         ( prod_list.line_no = lot_bin_prod.line_no) and  
         ( prod_list.prod_no = lot_bin_prod.tran_no) and  
         ( prod_list.prod_ext = lot_bin_prod.tran_ext) 
join #torder t (nolock) on ( produce.prod_no = t.h_prod_no ) and ( produce.prod_ext = t.h_prod_ext ) 
WHERE produce.status >= 'N' AND  produce.status < 'R' 
ORDER BY prod_list.location ASC, prod_list.line_no ASC   

UPDATE #tpick 
set 	i_description=i.description,
		 	i_bin_no=i.bin_no,
		 	i_commit_ed=i.commit_ed,
		 	i_uom=i.uom,
			i_in_stock=i.in_stock,
			i_status=i.status
FROM inventory i
WHERE i.part_no=#tpick.x_part_no and i.location=#tpick.x_location		


UPDATE #tpick
SET k_msg=i_uom+'  Bin: '+convert(char(12),l_bin_no)+'  Lot: '+l_lot_ser
WHERE x_lb_tracking='Y' and p_type <> 'J' and p_type <> 'R'

UPDATE #tpick
SET    p_description=i.description
FROM   inv_master i WHERE  p_part_no=i.part_no

select @row = isnull((select min(row_id) from #tpick where x_note = ''),0)
while @row <> 0
begin
  SELECT @parent=isnull( (select x_pline from #tpick where row_id = @row and x_pline <> x_line_no),0)
 
  if @parent > 0 
  begin
    select @asmpart=isnull( (select part_no from prod_list, #tpick 
    where prod_list.prod_no = #tpick.p_prod_no AND 
    prod_list.prod_ext = #tpick.p_prod_ext AND 
    prod_list.line_no = @parent and #tpick.row_id = @row), '' ) 
  end
  else 
  begin
    select @asmpart=isnull( (select p_part_no from #tpick where row_id = @row),'')
  end

  if @asmpart > '' 
  begin
    UPDATE #tpick 
    set x_note = CASE WHEN w.note is null THEN '' ELSE w.note END,
      x_note2 = CASE WHEN w.note2 is null THEN '' ELSE w.note2 END,
      x_note3 = CASE WHEN w.note3 is null THEN '' ELSE w.note3 END,
      x_note4 = CASE WHEN w.note4 is null THEN '' ELSE w.note4 END
    FROM what_part w, #tpick p
    WHERE w.asm_no=@asmpart and w.seq_no=p.x_seq_no and w.part_no=p.x_part_no and 
	 ( w.location = p.x_location OR w.location = 'ALL' ) and p.row_id = @row

    UPDATE #tpick 
    set x_note = CASE WHEN w.note is null THEN '' ELSE w.note END,
      x_note2 = CASE WHEN w.note2 is null THEN '' ELSE w.note2 END,
      x_note3 = CASE WHEN w.note3 is null THEN '' ELSE w.note3 END,
      x_note4 = CASE WHEN w.note4 is null THEN '' ELSE w.note4 END
    FROM what_part w, #tpick p, resource_group r
    WHERE w.asm_no=@asmpart and w.seq_no=p.x_seq_no and w.part_no=r.group_part_no and 
         r.resource_part_no = p.x_part_no and
	 ( w.location = p.x_location OR w.location = 'ALL' ) and p.row_id = @row
  end
  select @row = isnull((select min(row_id) from #tpick where x_note = '' and row_id > @row),0)
end

  SELECT p_prod_no         ,          p_prod_ext         ,
         p_status           ,         p_sch_date         ,
         isnull(p_part_no,'')          ,         substring(p_description,1,100)      ,			-- mls 5/22/01
         p_staging_area     ,         p_project          ,
         p_sch_qty          ,         p_type             ,
	 p_prod_date        ,         p_qty,
         p_location,
         0, -- x_level                  ,
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
         k_flag,
         case when p_type = 'R' then 0 else x_pline end  ,					-- mls 8/29/03 SCR 31816
         x_constrain,
         case when p_type = 'R' then x_pline else 0 end sort_order,				-- mls 8/29/03 SCR 31816
	 x_note2, x_note3, x_note4,

replicate (' ',11 - datalength(convert(varchar(11),p_prod_no))) + convert(varchar(11),p_prod_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),p_prod_ext))) + convert(varchar(5),p_prod_ext),
'.',
',',
case when @order = 0 -- order by prod_no
then replicate (' ',11 - datalength(convert(varchar(11),p_prod_no))) + convert(varchar(11),p_prod_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),p_prod_ext))) + convert(varchar(5),p_prod_ext)
else p_location end,
case when @order = 0 -- order by prod_no
then p_location
else replicate (' ',11 - datalength(convert(varchar(11),p_prod_no))) + convert(varchar(11),p_prod_no) + '.' +
replicate (' ',5 - datalength(convert(varchar(5),p_prod_ext))) + convert(varchar(5),p_prod_ext) end,
@order,
datalength(rtrim(replace(cast(p_sch_qty  as varchar(40)),'0',' '))) - 
charindex('.',cast(p_sch_qty  as varchar(40))),	-- sch qty precision
datalength(rtrim(replace(cast(x_planned  as varchar(40)),'0',' '))) - 
charindex('.',cast(x_planned  as varchar(40))),	-- planned qty precision
datalength(rtrim(replace(cast(x_picked  as varchar(40)),'0',' '))) - 
charindex('.',cast(x_picked  as varchar(40))),	-- picked qty precision
datalength(rtrim(replace(cast(l_uom_qty  as varchar(40)),'0',' '))) - 
charindex('.',cast(l_uom_qty  as varchar(40)))	-- bin qty precision


  FROM   #tpick  


update p
set status = 'Q'
from produce p, #torder t
where p.prod_no = t.h_prod_no and p.prod_ext = t.h_prod_ext and p.status = 'P' 


END
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_pickprod] TO [public]
GO
