CREATE TABLE [dbo].[produce_all]
(
[timestamp] [timestamp] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[prod_date] [datetime] NOT NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[prod_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sch_no] [int] NULL,
[down_time] [int] NOT NULL,
[shift] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty_scheduled] [decimal] (20, 8) NULL,
[qty_scheduled_orig] [decimal] (20, 8) NULL,
[build_to_bom] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_entered] [datetime] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[project_key] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[staging_area] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sch_date] [datetime] NULL,
[conv_factor] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[printed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[end_sch_date] [datetime] NULL,
[tot_avg_cost] [decimal] (20, 8) NOT NULL,
[tot_direct_dolrs] [decimal] (20, 8) NOT NULL,
[tot_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[tot_util_dolrs] [decimal] (20, 8) NOT NULL,
[tot_labor] [decimal] (20, 8) NOT NULL,
[est_avg_cost] [decimal] (20, 8) NOT NULL,
[est_direct_dolrs] [decimal] (20, 8) NOT NULL,
[est_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[est_util_dolrs] [decimal] (20, 8) NOT NULL,
[est_labor] [decimal] (20, 8) NOT NULL,
[tot_prod_avg_cost] [decimal] (20, 8) NOT NULL,
[tot_prod_direct_dolrs] [decimal] (20, 8) NOT NULL,
[tot_prod_ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[tot_prod_util_dolrs] [decimal] (20, 8) NOT NULL,
[tot_prod_labor] [decimal] (20, 8) NOT NULL,
[scrapped] [decimal] (20, 8) NOT NULL,
[cost_posted] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[est_no] [int] NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[hold_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__produce_a__hold___1ED07432] DEFAULT ('N'),
[hold_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fg_cost_ind] [int] NULL CONSTRAINT [DF__produce_a__fg_co__1FC4986B] DEFAULT ((0)),
[sub_com_cost_ind] [int] NULL CONSTRAINT [DF__produce_a__sub_c__20B8BCA4] DEFAULT ((0)),
[resource_cost_ind] [int] NULL CONSTRAINT [DF__produce_a__resou__21ACE0DD] DEFAULT ((0)),
[orig_prod_no] [int] NULL,
[orig_prod_ext] [int] NULL,
[custom_plan] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__produce_a__custo__22A10516] DEFAULT ('N'),
[bom_rev] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wopick_ctrl_num] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF_produce_wopick_ctrl_num] DEFAULT ('')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delprd] ON [dbo].[produce_all]   FOR DELETE AS 
begin
if exists (select * from config where flag='TRIG_DEL_PROD' and value_str='DISABLE')
	return
else
	begin
	rollback tran
	exec adm_raiserror 76099 ,'You Can Not Delete Production!' 
	return
	end
end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600insprd] ON [dbo].[produce_all]   FOR INSERT AS 
BEGIN
if exists (select * from config where flag='TRIG_INS_PROD' and value_str='DISABLE') return
if exists (select * from inserted 
	where status in ('R', 'S' ))
	begin
	rollback tran 
	exec adm_raiserror 86033, 'You Cannot Post Finished Production With QC Pending!'
	return
	end
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updprd] ON [dbo].[produce_all]   FOR UPDATE AS 
begin

declare @reg int, @reg2 int, @ecost decimal(20,8), @edir decimal(20,8), @elab decimal(20,8),
	@eovhd decimal(20,8), @eutil decimal(20,8), @xlp int

if NOT update(status) return

DECLARE @i_prod_no int, @i_prod_ext int, @i_prod_date datetime, @i_part_type varchar(10),
@i_part_no varchar(30), @i_location varchar(10), @i_qty decimal(20,8), @i_prod_type varchar(10),
@i_sch_no int, @i_down_time int, @i_shift char(1), @i_who_entered varchar(20),
@i_qty_scheduled decimal(20,8), @i_qty_scheduled_orig decimal(20,8), @i_build_to_bom char(1),
@i_date_entered datetime, @i_status char(1), @i_project_key varchar(10), @i_sch_flag char(1),
@i_staging_area varchar(12), @i_sch_date datetime, @i_conv_factor decimal(20,8), @i_uom char(2),
@i_printed char(1), @i_void char(1), @i_void_who varchar(20), @i_void_date datetime,
@i_note varchar(255), @i_end_sch_date datetime, @i_tot_avg_cost decimal(20,8),
@i_tot_direct_dolrs decimal(20,8), @i_tot_ovhd_dolrs decimal(20,8),
@i_tot_util_dolrs decimal(20,8), @i_tot_labor decimal(20,8), @i_est_avg_cost decimal(20,8),
@i_est_direct_dolrs decimal(20,8), @i_est_ovhd_dolrs decimal(20,8),
@i_est_util_dolrs decimal(20,8), @i_est_labor decimal(20,8), @i_tot_prod_avg_cost decimal(20,8),
@i_tot_prod_direct_dolrs decimal(20,8), @i_tot_prod_ovhd_dolrs decimal(20,8),
@i_tot_prod_util_dolrs decimal(20,8), @i_tot_prod_labor decimal(20,8), @i_scrapped decimal(20,8),
@i_cost_posted char(1), @i_qc_flag char(1), @i_order_no int, @i_est_no int,
@i_description varchar(255), @i_row_id int, @i_hold_flag char(1), @i_hold_code varchar(8),
@i_posting_code varchar(8), @i_fg_cost_ind int, @i_sub_com_cost_ind int,
@i_resource_cost_ind int, @i_orig_prod_no int, @i_orig_prod_ext int, @i_custom_plan char(1),
@i_bom_rev varchar(10),
@d_prod_no int, @d_prod_ext int, @d_prod_date datetime, @d_part_type varchar(10),
@d_part_no varchar(30), @d_location varchar(10), @d_qty decimal(20,8), @d_prod_type varchar(10),
@d_sch_no int, @d_down_time int, @d_shift char(1), @d_who_entered varchar(20),
@d_qty_scheduled decimal(20,8), @d_qty_scheduled_orig decimal(20,8), @d_build_to_bom char(1),
@d_date_entered datetime, @d_status char(1), @d_project_key varchar(10), @d_sch_flag char(1),
@d_staging_area varchar(12), @d_sch_date datetime, @d_conv_factor decimal(20,8), @d_uom char(2),
@d_printed char(1), @d_void char(1), @d_void_who varchar(20), @d_void_date datetime,
@d_note varchar(255), @d_end_sch_date datetime, @d_tot_avg_cost decimal(20,8),
@d_tot_direct_dolrs decimal(20,8), @d_tot_ovhd_dolrs decimal(20,8),
@d_tot_util_dolrs decimal(20,8), @d_tot_labor decimal(20,8), @d_est_avg_cost decimal(20,8),
@d_est_direct_dolrs decimal(20,8), @d_est_ovhd_dolrs decimal(20,8),
@d_est_util_dolrs decimal(20,8), @d_est_labor decimal(20,8), @d_tot_prod_avg_cost decimal(20,8),
@d_tot_prod_direct_dolrs decimal(20,8), @d_tot_prod_ovhd_dolrs decimal(20,8),
@d_tot_prod_util_dolrs decimal(20,8), @d_tot_prod_labor decimal(20,8), @d_scrapped decimal(20,8),
@d_cost_posted char(1), @d_qc_flag char(1), @d_order_no int, @d_est_no int,
@d_description varchar(255), @d_row_id int, @d_hold_flag char(1), @d_hold_code varchar(8),
@d_posting_code varchar(8), @d_fg_cost_ind int, @d_sub_com_cost_ind int,
@d_resource_cost_ind int, @d_orig_prod_no int, @d_orig_prod_ext int, @d_custom_plan char(1),
@d_bom_rev varchar(10)

DECLARE t700updprod_cursor CURSOR LOCAL FOR
SELECT i.prod_no, i.prod_ext, i.prod_date, i.part_type, i.part_no, i.location, i.qty,
i.prod_type, i.sch_no, i.down_time, i.shift, i.who_entered, i.qty_scheduled,
i.qty_scheduled_orig, i.build_to_bom, i.date_entered, i.status, i.project_key, i.sch_flag,
i.staging_area, i.sch_date, i.conv_factor, i.uom, i.printed, i.void, i.void_who, i.void_date,
i.note, i.end_sch_date, i.tot_avg_cost, i.tot_direct_dolrs, i.tot_ovhd_dolrs, i.tot_util_dolrs,
i.tot_labor, i.est_avg_cost, i.est_direct_dolrs, i.est_ovhd_dolrs, i.est_util_dolrs,
i.est_labor, i.tot_prod_avg_cost, i.tot_prod_direct_dolrs, i.tot_prod_ovhd_dolrs,
i.tot_prod_util_dolrs, i.tot_prod_labor, i.scrapped, i.cost_posted, i.qc_flag, i.order_no,
i.est_no, i.description, i.row_id, i.hold_flag, i.hold_code, i.posting_code, i.fg_cost_ind,
i.sub_com_cost_ind, i.resource_cost_ind, i.orig_prod_no, i.orig_prod_ext, i.custom_plan,
i.bom_rev,
d.prod_no, d.prod_ext, d.prod_date, d.part_type, d.part_no, d.location, d.qty,
d.prod_type, d.sch_no, d.down_time, d.shift, d.who_entered, d.qty_scheduled,
d.qty_scheduled_orig, d.build_to_bom, d.date_entered, d.status, d.project_key, d.sch_flag,
d.staging_area, d.sch_date, d.conv_factor, d.uom, d.printed, d.void, d.void_who, d.void_date,
d.note, d.end_sch_date, d.tot_avg_cost, d.tot_direct_dolrs, d.tot_ovhd_dolrs, d.tot_util_dolrs,
d.tot_labor, d.est_avg_cost, d.est_direct_dolrs, d.est_ovhd_dolrs, d.est_util_dolrs,
d.est_labor, d.tot_prod_avg_cost, d.tot_prod_direct_dolrs, d.tot_prod_ovhd_dolrs,
d.tot_prod_util_dolrs, d.tot_prod_labor, d.scrapped, d.cost_posted, d.qc_flag, d.order_no,
d.est_no, d.description, d.row_id, d.hold_flag, d.hold_code, d.posting_code, d.fg_cost_ind,
d.sub_com_cost_ind, d.resource_cost_ind, d.orig_prod_no, d.orig_prod_ext, d.custom_plan,
d.bom_rev
from inserted i, deleted d
where i.row_id=d.row_id and i.status != d.status

OPEN t700updprod_cursor
FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_prod_date, @i_part_type, @i_part_no, @i_location, @i_qty,
@i_prod_type, @i_sch_no, @i_down_time, @i_shift, @i_who_entered, @i_qty_scheduled,
@i_qty_scheduled_orig, @i_build_to_bom, @i_date_entered, @i_status, @i_project_key, @i_sch_flag,
@i_staging_area, @i_sch_date, @i_conv_factor, @i_uom, @i_printed, @i_void, @i_void_who,
@i_void_date, @i_note, @i_end_sch_date, @i_tot_avg_cost, @i_tot_direct_dolrs, @i_tot_ovhd_dolrs,
@i_tot_util_dolrs, @i_tot_labor, @i_est_avg_cost, @i_est_direct_dolrs, @i_est_ovhd_dolrs,
@i_est_util_dolrs, @i_est_labor, @i_tot_prod_avg_cost, @i_tot_prod_direct_dolrs,
@i_tot_prod_ovhd_dolrs, @i_tot_prod_util_dolrs, @i_tot_prod_labor, @i_scrapped, @i_cost_posted,
@i_qc_flag, @i_order_no, @i_est_no, @i_description, @i_row_id, @i_hold_flag, @i_hold_code,
@i_posting_code, @i_fg_cost_ind, @i_sub_com_cost_ind, @i_resource_cost_ind, @i_orig_prod_no,
@i_orig_prod_ext, @i_custom_plan, @i_bom_rev,
@d_prod_no, @d_prod_ext, @d_prod_date, @d_part_type, @d_part_no, @d_location, @d_qty,
@d_prod_type, @d_sch_no, @d_down_time, @d_shift, @d_who_entered, @d_qty_scheduled,
@d_qty_scheduled_orig, @d_build_to_bom, @d_date_entered, @d_status, @d_project_key, @d_sch_flag,
@d_staging_area, @d_sch_date, @d_conv_factor, @d_uom, @d_printed, @d_void, @d_void_who,
@d_void_date, @d_note, @d_end_sch_date, @d_tot_avg_cost, @d_tot_direct_dolrs, @d_tot_ovhd_dolrs,
@d_tot_util_dolrs, @d_tot_labor, @d_est_avg_cost, @d_est_direct_dolrs, @d_est_ovhd_dolrs,
@d_est_util_dolrs, @d_est_labor, @d_tot_prod_avg_cost, @d_tot_prod_direct_dolrs,
@d_tot_prod_ovhd_dolrs, @d_tot_prod_util_dolrs, @d_tot_prod_labor, @d_scrapped, @d_cost_posted,
@d_qc_flag, @d_order_no, @d_est_no, @d_description, @d_row_id, @d_hold_flag, @d_hold_code,
@d_posting_code, @d_fg_cost_ind, @d_sub_com_cost_ind, @d_resource_cost_ind, @d_orig_prod_no,
@d_orig_prod_ext, @d_custom_plan, @d_bom_rev

While @@FETCH_STATUS = 0
begin
  if @d_status = 'S'
  begin
    rollback tran 
    exec adm_raiserror 96031, 'You Can NOT Change POSTED Production!'
    return
  end

-- mls 12/03/04 SCR 33596 --------------------------------------------------------------------------------
  if @i_status in ('R','S')
  begin
    if exists (select 1 from lot_bin_prod s where tran_no = @i_prod_no and tran_ext = @i_prod_ext
      and not exists (select 1 from prod_list l where l.prod_no = @i_prod_no and l.prod_ext = @i_prod_ext
      and l.line_no = s.line_no))
    begin
      rollback tran
      exec adm_raiserror 832114, 'Lot bin records on lot_bin_prod do not relate to a line on the production.'
      RETURN
    end
  end

  if @i_status = 'Q' and @d_status < 'Q'
  begin											-- mls 10/20/99
    
    SELECT 
      @ecost=sum(isnull(p.plan_qty * 
        case when i.inv_cost_method in ('S','F','L') or i.status = 'R' then i.std_cost
        else i.avg_cost end,0)),
      @edir=sum(isnull(p.plan_qty * 
        case when i.inv_cost_method in ('S','F','L') or i.status = 'R' then i.std_direct_dolrs
        else i.avg_direct_dolrs end,0)),
      @eovhd=sum(isnull(p.plan_qty * 
        case when i.inv_cost_method in ('S','F','L') or i.status = 'R' then i.std_ovhd_dolrs
        else i.avg_ovhd_dolrs end,0)),
      @eutil=sum(isnull(p.plan_qty * 
        case when i.inv_cost_method in ('S','F','L') or i.status = 'R' then i.std_util_dolrs
        else i.avg_util_dolrs end,0)),
      @elab=sum(isnull(p.plan_qty * 
        case when i.inv_cost_method in ('S','F','L') or i.status = 'R' then i.std_labor
        else i.labor end,0))
    FROM prod_list p, inventory i
    WHERE p.prod_no=@i_prod_no and p.prod_ext=@i_prod_ext and
      p.part_no=i.part_no and p.location=i.location and p.direction=-1 and p.plan_qty != 0

    UPDATE produce_all 
    SET est_avg_cost=isnull(@ecost,0), 						-- mls 8/24/05 SCR 35363
	est_direct_dolrs=isnull(@edir,0),
	est_ovhd_dolrs=isnull(@eovhd,0),
      	est_util_dolrs=isnull(@eutil,0), 
	est_labor=isnull(@elab,0)
    WHERE prod_no= @i_prod_no and prod_ext= @i_prod_ext
  end 				-- mls 10/20/99

  
  UPDATE prod_list 
  SET status= @i_status 
  WHERE prod_no= @i_prod_no and prod_ext=@i_prod_ext and status != @i_status and direction = -1 

  
  UPDATE prod_list 
  SET status= @i_status 
  WHERE prod_no= @i_prod_no and prod_ext=@i_prod_ext and (status != @i_status and status < 'R')
    and direction = 1 

  if @i_status in ('S','V')
  begin
    INSERT prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
      ovhd_dolrs, labor, util_dolrs, tran_date, qty, status)
    SELECT @i_prod_no, @i_prod_ext, 0,
      CASE @i_prod_type WHEN 'J' THEN 'JOB_COST_TOTAL' ELSE 'COST_VARIANCE' END,
      p.tot_prod_avg_cost - p.tot_avg_cost  , 
      p.tot_prod_direct_dolrs - p.tot_direct_dolrs ,
      p.tot_prod_ovhd_dolrs - p.tot_ovhd_dolrs , p.tot_prod_labor - p.tot_labor ,
      p.tot_prod_util_dolrs - p.tot_util_dolrs , getdate(),			-- mls 4/13/00 SCR 22566
      1, 'N'
    FROM produce_all p
    WHERE  prod_no= @i_prod_no and prod_ext= @i_prod_ext
  end

FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_prod_date, @i_part_type, @i_part_no, @i_location, @i_qty,
@i_prod_type, @i_sch_no, @i_down_time, @i_shift, @i_who_entered, @i_qty_scheduled,
@i_qty_scheduled_orig, @i_build_to_bom, @i_date_entered, @i_status, @i_project_key, @i_sch_flag,
@i_staging_area, @i_sch_date, @i_conv_factor, @i_uom, @i_printed, @i_void, @i_void_who,
@i_void_date, @i_note, @i_end_sch_date, @i_tot_avg_cost, @i_tot_direct_dolrs, @i_tot_ovhd_dolrs,
@i_tot_util_dolrs, @i_tot_labor, @i_est_avg_cost, @i_est_direct_dolrs, @i_est_ovhd_dolrs,
@i_est_util_dolrs, @i_est_labor, @i_tot_prod_avg_cost, @i_tot_prod_direct_dolrs,
@i_tot_prod_ovhd_dolrs, @i_tot_prod_util_dolrs, @i_tot_prod_labor, @i_scrapped, @i_cost_posted,
@i_qc_flag, @i_order_no, @i_est_no, @i_description, @i_row_id, @i_hold_flag, @i_hold_code,
@i_posting_code, @i_fg_cost_ind, @i_sub_com_cost_ind, @i_resource_cost_ind, @i_orig_prod_no,
@i_orig_prod_ext, @i_custom_plan, @i_bom_rev,
@d_prod_no, @d_prod_ext, @d_prod_date, @d_part_type, @d_part_no, @d_location, @d_qty,
@d_prod_type, @d_sch_no, @d_down_time, @d_shift, @d_who_entered, @d_qty_scheduled,
@d_qty_scheduled_orig, @d_build_to_bom, @d_date_entered, @d_status, @d_project_key, @d_sch_flag,
@d_staging_area, @d_sch_date, @d_conv_factor, @d_uom, @d_printed, @d_void, @d_void_who,
@d_void_date, @d_note, @d_end_sch_date, @d_tot_avg_cost, @d_tot_direct_dolrs, @d_tot_ovhd_dolrs,
@d_tot_util_dolrs, @d_tot_labor, @d_est_avg_cost, @d_est_direct_dolrs, @d_est_ovhd_dolrs,
@d_est_util_dolrs, @d_est_labor, @d_tot_prod_avg_cost, @d_tot_prod_direct_dolrs,
@d_tot_prod_ovhd_dolrs, @d_tot_prod_util_dolrs, @d_tot_prod_labor, @d_scrapped, @d_cost_posted,
@d_qc_flag, @d_order_no, @d_est_no, @d_description, @d_row_id, @d_hold_flag, @d_hold_code,
@d_posting_code, @d_fg_cost_ind, @d_sub_com_cost_ind, @d_resource_cost_ind, @d_orig_prod_no,
@d_orig_prod_ext, @d_custom_plan, @d_bom_rev
end -- while

CLOSE t700updprod_cursor
DEALLOCATE t700updprod_cursor

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[tdc_produce_tg] ON [dbo].[produce_all]
FOR INSERT, UPDATE
AS

/* Do not allow users to save production orders where the part is make type ('M') */
IF EXISTS(SELECT * FROM inserted i WHERE i.prod_type = 'M' AND i.status <> 'V')
BEGIN
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	RAISERROR ('Part cannot be make type.', 16 , 1)
	RETURN
END

IF EXISTS (SELECT * FROM inserted WHERE status <= 'Q')
	RETURN

/****** Lets ensure they've used what they've picked, otherwise prompt them to unpick  *******/
IF EXISTS (SELECT *
	     FROM tdc_wo_pick tp, inserted i
	    WHERE tp.prod_no  = i.prod_no
	      AND tp.prod_ext = i.prod_ext
	      AND (tp.pick_qty - tp.used_qty) > 0)
BEGIN 
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

	DECLARE @errmsg varchar(255)

	SELECT @errmsg = err_msg 
	  FROM  dbo.tdc_lookup_error (NOLOCK) 
	 WHERE source = 'CO' 
	   AND module = 'WOP' 
	   AND trans = 'WOCLOSE' 
	   AND err_no = 3

	RAISERROR(@errmsg, 16,1)
	RETURN 
END

/**** Lets remove the records off the queue and soft alloc when close work order ***/
DELETE tdc_soft_alloc_tbl
  FROM inserted i
 WHERE tdc_soft_alloc_tbl.order_no   = i.prod_no 
   AND tdc_soft_alloc_tbl.order_ext  = i.prod_ext 
   AND tdc_soft_alloc_tbl.order_type = 'W'

DELETE tdc_pick_queue
  FROM inserted i
 WHERE i.prod_no  = tdc_pick_queue.trans_type_no 
   AND i.prod_ext = tdc_pick_queue.trans_type_ext 
   AND tdc_pick_queue.trans = 'WOPPICK' 
GO
CREATE NONCLUSTERED INDEX [prodest] ON [dbo].[produce_all] ([est_no], [prod_no], [prod_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [prod2] ON [dbo].[produce_all] ([prod_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [prod1] ON [dbo].[produce_all] ([prod_no], [prod_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [producem1] ON [dbo].[produce_all] ([void], [status], [location], [prod_no], [prod_ext]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[produce_all] TO [public]
GO
GRANT SELECT ON  [dbo].[produce_all] TO [public]
GO
GRANT INSERT ON  [dbo].[produce_all] TO [public]
GO
GRANT DELETE ON  [dbo].[produce_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[produce_all] TO [public]
GO
