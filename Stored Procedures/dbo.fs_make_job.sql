SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_make_job] @eno int, @ord int=0, @ext int=0, 
                             @lno int=0, @qty decimal(20,8)  AS 

BEGIN
declare @eqty decimal(20,8)
declare @pno integer
declare @cjob varchar(30), @cprod varchar(30), @c_eno varchar(20)
declare @stat char(1),     @edesc varchar(255)
select @stat  = 'J'
select @eqty   = 1
select @c_eno = convert(varchar(20), @eno )
select @cjob  = 'Est No ' + @c_eno

select @edesc = description
  from estimates
 where est_no=@eno

select @eqty = Max(quoted_qty)
       from estimates
       where est_no = @eno and quoted_qty <= @qty

if @eqty is null begin
    select @eqty = Min(quoted_qty)
           from estimates
           where est_no = @eno
end

if @eqty is null select @eqty = 0

update next_prod_no set last_no=last_no+1
select @pno=last_no from next_prod_no

      INSERT dbo.produce_all ( prod_no           , prod_ext          , prod_date         , 
                           part_type         , part_no           , location          , 
                           qty               , prod_type         , sch_no            , 
                           shift             , who_entered       , qty_scheduled     ,
			   build_to_bom      , date_entered      , status            ,
			   project_key       , sch_flag          , staging_area      , 
                           sch_date          , conv_factor       , uom               , 
                           printed           , void              , void_who          , 
                           void_date         , note              , end_sch_date      ,
			   tot_avg_cost      , tot_direct_dolrs  , tot_ovhd_dolrs    ,
			   tot_util_dolrs    , tot_labor         ,
			   tot_prod_avg_cost , tot_prod_direct_dolrs , tot_prod_ovhd_dolrs ,
			   tot_prod_util_dolrs , tot_prod_labor  ,
			   est_avg_cost      , est_direct_dolrs  , est_ovhd_dolrs    ,
			   est_util_dolrs    , est_labor         ,
			   scrapped          , cost_posted       , 
                           qc_flag           , order_no          , down_time         ,
                           est_no            , description       , qty_scheduled_orig ) -- mls 2/21/02 SCR 28408
                    SELECT @pno              , 0                 , getdate()         , 
                           'J'               , @cjob             , location          , 
                           0                 , 'J'               , 0                 , 
                           '1'               , who_entered       , @qty              ,
			   null              , getdate()         , @stat             , 
                           null              , 'P'               , null              , 
                           getdate()         , 
                           1.0               , null              , 
                           'N'               , 'N'               , null              , 
                           null              , note              , null              ,
			   0                 , 0                 , 0                 ,
			   0                 , 0                 ,
			   0                 , 0                 , 0                 ,
			   0                 , 0                 ,
			   0                 , 0                 , 0                 ,
			   0                 , 0                 ,
			   0                 , 'N'               , 
                           'N'               , 0                 , 0                 ,
                           @eno              , description       , @qty			-- mls 2/21/02 SCR 28408
                FROM dbo.estimates
               WHERE est_no=@eno and quoted_qty=@eqty

INSERT prod_list ( prod_no,        prod_ext,          line_no,           
                   seq_no,         part_no,           location,          
                   description,    plan_qty,          used_qty,          
                   attrib,         uom,               conv_factor,       
                   who_entered,    note,              lb_tracking,       
                   bench_stock,    status,            constrain,
                   plan_pcs,       pieces,            scrap_pcs,
                   part_type,      direction,         cost_pct,
                   p_qty,          p_line  ) 
            SELECT @pno,           0,                 e.line_no+1,
                   convert(varchar(4), ( 1000 + 100*line_no) ),
                                   e.part_no,         e.location,
                   e.description,  case when e.fixed='Y' then qty else (qty * @qty) end,               
                   0,
                   null,           i.uom,             1.0,
                   e.who_entered,  e.note,            i.lb_tracking,
                   'N',            @stat,             'N',
                   0,              0,                 0,
                   e.part_type,    -1,                0,
                   case when e.fixed='Y' then 0 else qty end,            0
              FROM est_list e
	left outer join inv_master i (nolock) on e.part_no = i.part_no 
             WHERE e.est_no=@eno and e.quoted_qty=@eqty

select @cprod = convert(varchar(20), @pno)

UPDATE ord_list SET part_type    = 'J',
                    orig_part_no = part_no,
                    part_no      = @cprod,
                    description  = @edesc
       WHERE ord_list.order_no = @ord and ord_list.order_ext = @ext and
             ord_list.line_no  = @lno and
             ord_list.part_type = 'E' and 
             ord_list.part_no = @c_eno
END
GO
GRANT EXECUTE ON  [dbo].[fs_make_job] TO [public]
GO
