CREATE TABLE [dbo].[prod_list]
(
[timestamp] [timestamp] NOT NULL,
[prod_no] [int] NOT NULL,
[prod_ext] [int] NOT NULL,
[line_no] [int] NOT NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_qty] [decimal] (20, 8) NOT NULL,
[used_qty] [decimal] (20, 8) NOT NULL,
[attrib] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_pcs] [decimal] (20, 8) NOT NULL,
[pieces] [decimal] (20, 8) NOT NULL,
[scrap_pcs] [decimal] (20, 8) NOT NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[direction] [int] NULL CONSTRAINT [DF__prod_list__direc__0CB1C3F7] DEFAULT ((-1)),
[cost_pct] [decimal] (20, 8) NULL CONSTRAINT [DF__prod_list__cost___0DA5E830] DEFAULT ((0)),
[p_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__prod_list__p_qty__0E9A0C69] DEFAULT ((0)),
[p_line] [int] NULL CONSTRAINT [DF__prod_list__p_lin__0F8E30A2] DEFAULT ((0)),
[row_id] [int] NOT NULL IDENTITY(1, 1),
[p_pcs] [decimal] (20, 8) NULL CONSTRAINT [DF__prod_list__p_pcs__108254DB] DEFAULT ((0)),
[qc_no] [int] NULL CONSTRAINT [DF__prod_list__qc_no__11767914] DEFAULT ((0)),
[oper_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__prod_list__oper___126A9D4D] DEFAULT ('N'),
[pool_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__prod_list__pool___135EC186] DEFAULT ((1.0)),
[last_tran_date] [datetime] NULL,
[fixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__prod_list__fixed__1452E5BF] DEFAULT ('N'),
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__prod_list__activ__154709F8] DEFAULT ('A'),
[eff_date] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700delprodl] ON [dbo].[prod_list] FOR DELETE AS 

declare @xlp int, @retval int, @part varchar(30), @loc varchar(10), @cdir int, @qty decimal(20,8),
	@tran_code char(1), @xqty decimal(20,8), @tran_no int, @tran_ext int, @account varchar(10),
	@tran_date datetime, @tran_line int, @tran_age datetime, @unitcost decimal(20,8),
	@direct decimal(20,8), @overhead decimal(20,8), @labor decimal(20,8), @utility decimal(20,8) 

declare @dl_part_no varchar(30), @dl_location varchar(10), @dl_part_type char(1),	-- mls 12/6/02 SCR 30409 start
@inv_status char(1)									-- mls 12/6/02 SCR 30409 end

if exists (select 1 from deleted where status >='S')
begin
  if exists (select * from config where flag='TRIG_DEL_PRDL' and value_str='DISABLE')
  return

  rollback tran
  exec adm_raiserror 76199, 'You Can NOT Delete/Change A Produced Item That Is Completed!'
  return
end

if exists (select 1 from deleted where qc_no > 0) 
begin
  rollback tran 
  exec adm_raiserror 76135 ,'You Cannot Post Finished Production With QC Pending!'
  return
end

select @xlp=isnull((select min(row_id) from deleted where (constrain != 'C' and constrain != 'Y')),0)
while @xlp > 0
begin
  if exists (select 1 from deleted where row_id = @xlp and (used_qty != 0 or scrap_pcs != 0))	-- mls 5/30/02 SCR 29005 start
  begin
    rollback tran 
    exec adm_raiserror 76136, 'You Cannot delete subcomponents that have usage!'
    return
  end										-- mls 5/30/02 SCR 29005 end

  select @dl_part_no = part_no, @dl_location = location, @dl_part_type = part_type	-- mls 12/6/02 SCR 30409 start
  from deleted where row_id = @xlp

  select @inv_status = '!'
  IF @dl_part_type <> 'X' 									
  begin												
    select @inv_status = status from inv_master where part_no = @dl_part_no		
  END											-- mls 12/6/02 SCR 30409 end

  if isnull(@inv_status,'!') not in ('V','!') 						-- mls 12/6/02 SCR 30409 
  BEGIN											
    update inv_produce set sch_alloc=inv_produce.sch_alloc - ((deleted.plan_qty - deleted.used_qty) * deleted.conv_factor)
    from deleted 
    where deleted.direction=-1 and inv_produce.part_no=deleted.part_no and inv_produce.location=deleted.location and
      (deleted.status='N' OR deleted.status='P' OR deleted.status='Q') and (deleted.plan_qty - deleted.used_qty)>0 and
      deleted.row_id=@xlp
  end

  delete lot_bin_prod 
  from deleted
  where lot_bin_prod.tran_no=deleted.prod_no and  lot_bin_prod.tran_ext=deleted.prod_ext and	
    lot_bin_prod.line_no=deleted.line_no and lot_bin_prod.part_no=deleted.part_no and
    deleted.row_id=@xlp

  select @xlp=isnull((select min(row_id) from deleted where (constrain != 'C' and constrain != 'Y') and row_id > @xlp),0)
end 
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700insprodl] ON [dbo].[prod_list] FOR insert AS 
BEGIN

if NOT (update(status) or update (constrain) or update(part_no) or update(location) or		-- mls 03/30/00 SCR 22716 start
update(prod_no) or update(prod_ext) or update(line_no) or update(conv_factor) or 
update(qc_no) or update(part_type) or update(direction) or update(used_qty) or
update (scrap_pcs) or update(cost_pct) or update (plan_qty) or update(lb_tracking))
  return											-- mls 03/30/00 SCR 22716 end

DECLARE @i_prod_no int, @i_prod_ext int, @i_line_no int, @i_seq_no varchar(4),
@i_part_no varchar(30), @i_location varchar(10), @i_description varchar(255),
@i_plan_qty decimal(20,8), @i_used_qty decimal(20,8), @i_attrib decimal(20,8), @i_uom char(2),
@i_conv_factor decimal(20,8), @i_who_entered varchar(20), @i_note varchar(255),
@i_lb_tracking char(1), @i_bench_stock char(1), @i_status char(1), @i_constrain char(1),
@i_plan_pcs decimal(20,8), @i_pieces decimal(20,8), @i_scrap_pcs decimal(20,8),
@i_part_type char(1), @i_direction int, @i_cost_pct decimal(20,8), @i_p_qty decimal(20,8),
@i_p_line int, @i_row_id int, @i_p_pcs decimal(20,8), @i_qc_no int, @i_oper_status char(1),
@i_pool_qty decimal(20,8), @i_last_tran_date datetime, @i_fixed char(1), @i_active char(1),
@i_eff_date datetime, @typ char(1)

declare @a_unitcost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_utility decimal(20,8),
  @a_tran_data varchar(255), @a_tran_id int, @msg varchar(255),
  @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8), @labor decimal(20,8),
  @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_utility decimal(20,8),
  @tempcost decimal(20,8), @totcost decimal(20,8)

declare @apply_date datetime, @inv_status char(1), @prod_type char(1), @fg_cost_ind int,
  @sub_com_cost_ind int, @resource_cost_ind int, @prod_date datetime, @posting_code varchar(8),
  @company_id int, @natcode varchar(8), @COGS int, @in_stock decimal(20,8), 
  @i_produced_qty decimal(20,8), @a_tran_qty decimal(20,8), @i_hold_mfg decimal(20,8),
  @retval int, @m_qc_flag char(1), @qty decimal(20,8), @dtexp datetime,
  @inv_acct varchar(32), @direct_acct varchar(32),@ovhd_acct varchar(32),@util_acct varchar(32),
  @COGS_acct varchar(32), @COGS_acct_direct varchar(32),@COGS_acct_util varchar(32), @COGS_acct_ovhd varchar(32),
  @var_acct varchar(32), @var_direct varchar(32),@var_util varchar(32), @var_ovhd varchar(32),
  @wip_acct varchar(32),@wip_direct varchar(32),@wip_ovhd varchar(32),@wip_util varchar(32),
  @iloop int, @COGS_qty decimal(20,8), @cost decimal(20,8), @COGS_cost decimal(20,8), 
  @glaccount varchar(32), @wipaccount varchar(32), @COGSacct varchar(32),
  @line_descr varchar(50), @glcost decimal(20,8), @glqty decimal(20,8),
  @i_sch_alloc decimal(20,8), @i_usage_qty decimal(20,8)

declare @m_lb_tracking char(1), @m_status char(1),
@lb_sum decimal(20,8), @uom_sum decimal(20,8), @part_cnt int, @lb_part varchar(30), @lb_loc varchar(10),
@inv_lot_bin int, @used_qty decimal(20,8), 
@rc int

DECLARE t700insprod_cursor CURSOR LOCAL STATIC FOR
SELECT i.prod_no, i.prod_ext, i.line_no, i.seq_no, i.part_no, i.location, i.description,
i.plan_qty, i.used_qty, i.attrib, i.uom, i.conv_factor, i.who_entered, i.note, i.lb_tracking,
i.bench_stock, i.status, i.constrain, i.plan_pcs, i.pieces, i.scrap_pcs, i.part_type,
i.direction, i.cost_pct, i.p_qty, i.p_line, i.row_id, i.p_pcs, i.qc_no, i.oper_status,
i.pool_qty, i.last_tran_date, i.fixed, i.active, i.eff_date,
m.lb_tracking, m.status, m.qc_flag
from inserted i
left outer join inv_master m on m.part_no = i.part_no

OPEN t700insprod_cursor

if @@cursor_rows = 0
begin
  CLOSE t700insprod_cursor
  DEALLOCATE t700insprod_cursor
  return
end

FETCH NEXT FROM t700insprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_seq_no, @i_part_no, @i_location, @i_description,
@i_plan_qty, @i_used_qty, @i_attrib, @i_uom, @i_conv_factor, @i_who_entered, @i_note,
@i_lb_tracking, @i_bench_stock, @i_status, @i_constrain, @i_plan_pcs, @i_pieces, @i_scrap_pcs,
@i_part_type, @i_direction, @i_cost_pct, @i_p_qty, @i_p_line, @i_row_id, @i_p_pcs, @i_qc_no,
@i_oper_status, @i_pool_qty, @i_last_tran_date, @i_fixed, @i_active, @i_eff_date, @m_lb_tracking,
@inv_status, @m_qc_flag

While @@FETCH_STATUS = 0
begin
  select @apply_date = @i_last_tran_date			

  if @i_qc_no > 0 and @i_status in ('S','V')
  begin
    rollback tran 
    exec adm_raiserror 86131 ,'You Cannot Post Finished Production With QC Pending!'
    return
  end

  if @inv_lot_bin is null
    select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)

  IF @i_part_type != 'X' 									-- mls 03/30/00 SCR 22716
  begin												-- mls 03/30/00 SCR 22716
    if @m_lb_tracking is null
    begin
      rollback tran
      exec adm_raiserror 832111, 'Part does not exists in inventory.'
      RETURN
    end

    if not exists (select 1 from inv_produce (nolock)
    WHERE  part_no =  @i_part_no AND location =  @i_location)
    BEGIN
      rollback tran
      exec adm_raiserror 86132, 'Inventory Part Missing.  The transaction is being rolled back.'
      RETURN
    END

    if @inv_status = 'C'
    begin
      rollback tran 
      exec adm_raiserror 86138 ,'You Can Not consume/produce Custom Kit Items..'
      return
    end
  end
  ELSE
    select @inv_status = '!'

  if isnull(@m_lb_tracking,'N') != @i_lb_tracking
  begin
    rollback tran
    exec adm_raiserror 832112 ,'Lot bin tracking flag mismatch with inventory.'
    RETURN
  end

  select @lb_sum = sum(qty * direction),
    @uom_sum = sum(uom_qty * direction),
    @part_cnt = count(distinct (part_no + '!@#' + location)) ,
    @lb_part = min(part_no),
    @lb_loc = min(location)
  from lot_bin_prod (nolock)
  where tran_no = @i_prod_no and tran_ext = @i_prod_ext and line_no = @i_line_no

  select @used_qty = (@i_used_qty - case when @i_direction > 0 then @i_scrap_pcs else 0 end) * @i_direction
 
  select @lb_sum = isnull(@lb_sum,0), @uom_sum = isnull(@uom_sum,0), @part_cnt = isnull(@part_cnt,0),
    @lb_part = isnull(@lb_part,''), @lb_loc = isnull(@lb_loc,'')

  if isnull(@m_lb_tracking,'') = 'Y' 
  begin
    if @inv_lot_bin = 1
    begin 
      if @part_cnt > 1
      begin
        rollback tran
        exec adm_raiserror 832113 ,'More than one parts lot bin records found on lot_bin_prod for this prod line.'
        RETURN
      end
      if @uom_sum != @used_qty
      begin
        select @msg = 'Prod Line uom qty of [' + convert(varchar,@used_qty) + '] does not equal the lot and bin uom qty of [' + convert(varchar,@uom_sum) + '].'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @lb_sum != (@used_qty * @i_conv_factor)
      begin
        select @msg = 'Prod Line qty of [' + convert(varchar,(@used_qty * @i_conv_factor)) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) + '].'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @part_cnt > 0 and (@lb_part != @i_part_no or @lb_loc != @i_location)
      begin
        select @msg = 'Part/Location on lot_bin_recv is not the same as on prod_list table.'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
    end
    else
    begin
      if @part_cnt > 0 
      begin
        select @msg = 'You cannot have lot bin records on a production transaction when you are not lb tracking.'
        rollback tran
        exec adm_raiserror 832114, @msg
        RETURN
      end
    end
  END
  else
  begin
    if @part_cnt > 0
    begin
      rollback tran
      exec adm_raiserror 832114,'Lot bin records found on lot_bin_prod for this not lot/bin tracked part.'
      RETURN
    end
  end

  if @i_direction > 0 and (abs(@i_used_qty) - abs(@i_scrap_pcs)) < 0
  begin
    rollback tran 
    exec adm_raiserror 86133, 'Scrap Can NOT Exceed Quantity Produced!'
    return
  end

  if exists (select 1 from produce_all (nolock)
  where prod_no = @i_prod_no and prod_ext = @i_prod_ext and hold_flag='Y') 
  begin
    rollback tran 
    exec adm_raiserror 86134, 'You Can Not Modify A Held Production Order.'
    return
  end

  if exists (select 1 from produce_all (nolock)
  where prod_no = @i_prod_no and prod_ext = @i_prod_ext and status >= 'S') 
  begin
    rollback tran 
    exec adm_raiserror 86105, 'You Can Not Complete Produce Items AFTER Completing Production Header.'
    return
  end

  if (@i_constrain != 'C' and @i_constrain != 'Y')
  begin

  select @prod_type = p.prod_type, 									
    @fg_cost_ind = isnull(p.fg_cost_ind,0),								-- mls 03/30/00 SCR 22697 start
    @sub_com_cost_ind = isnull(sub_com_cost_ind,0), 
    @resource_cost_ind = isnull(resource_cost_ind,0),
    @prod_date = isnull(prod_date,getdate())								-- mls 03/30/00 SCR 22697 end			
  from produce_all p (nolock)
  where p.prod_no = @i_prod_no and p.prod_ext = @i_prod_ext						

  if @inv_status = '!' and @i_direction = -1 and @prod_type = 'J'					-- mls 4/17/01 SCR 26742 start
  begin
    SELECT @posting_code = l.aracct_code
    from locations_all l (nolock) where location = @i_location
  end
  else
  begin		
    SELECT @posting_code = l.acct_code
    from inv_list l
    WHERE l.part_no = @i_part_no AND l.location = @i_location	

    if @@rowcount = 0										-- mls 10/14/99 start
    begin
	rollback tran
	exec adm_raiserror 9910142, 'Part does not exist in inventory'
	return
    end												-- mls 10/14/99 end
  end

  -- MLS 3/30/00 SCR 22697
  -- NOTE: fg_cost_ind determines which cost to use for the finished good in reverse manufacturing. If the
  -- ind = 0 then use the current costs.  If the ind != 0 then use the cost from the production that is being reversed.
  -- sub_com_cost_ind determines which cost to use for the subcomponent costs in reverse manufacturing.  If the
  -- ind = 0 then use the current costs.  If the ind != 0 then use the cost from the production that is being reversed.
  -- resource_ind determins whether the resource costs are going to be reversed on a reversal.  If the ind = 0
  -- then the costs will be reversed.  If the ind != 0 then the costs will not be reversed.

  select @apply_date = isnull(@apply_date,@prod_date)						-- mls 4/13/00 SCR 22566 

  if @i_direction = 1	-- Finished Good									-- mls 10/14/99 start
  begin
    if @company_id is NULL	
    begin
      SELECT @company_id = company_id, @natcode = home_currency FROM glco (nolock)
    end
 
    SELECT @COGS = 0
    select @i_produced_qty = 0, @i_hold_mfg = 0

    select @i_produced_qty = case when (@i_status in ('P','Q') and @prod_type = 'R') or @i_status = 'S'
      then (@i_used_qty - @i_scrap_pcs) * @i_conv_factor else 0 end,
      @i_hold_mfg = case when (@i_status in ('P','Q') and @prod_type != 'R') or @i_status = 'R'
      then (@i_used_qty - @i_scrap_pcs) * @i_conv_factor else 0 end

    if @i_produced_qty != 0 or @i_hold_mfg != 0
    begin
      select @a_tran_qty = (@i_used_qty - @i_scrap_pcs),
        @a_tran_data = isnull(@prod_type,' ') + convert(char(1),@fg_cost_ind) +
        convert(varchar(30),@i_cost_pct) + replicate(' ',30 - datalength(convert(varchar(30),@i_cost_pct))) +
        convert(varchar(30),@i_plan_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_plan_qty))) +
        convert(varchar(30),@i_used_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_used_qty))) 

      exec @retval = adm_inv_tran 
        'P', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_uom, 
        @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT, 
        @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, 0,
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
      if @retval <> 1
      begin
        rollback tran
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
        exec adm_raiserror 83202 ,@msg
        RETURN
      end

      select @d_unitcost = @a_unitcost/@a_tran_qty, @d_direct = @a_direct/@a_tran_qty,
        @d_overhead = @a_overhead/@a_tran_qty, @d_utility = @a_utility/@a_tran_qty

      update inv_produce set 
        produced_mtd=produced_mtd + @i_produced_qty,
	produced_ytd=produced_ytd + @i_produced_qty,
        hold_mfg = hold_mfg + @i_hold_mfg
      where part_no= @i_part_no and location= @i_location 

      -- mls 1/18/05 SCR 34050
      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'P', @i_produced_qty
      if @rc < 1
      begin
        select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
        rollback tran
        exec adm_raiserror 9910141, @msg
        return
      end
    end

    

    if @i_status = 'R' and @i_hold_mfg != 0 and @i_qc_no = 0 
    begin
      if isnull(@m_qc_flag,'N') = 'Y'
      begin
        select @qty=(@i_hold_mfg * @i_conv_factor), @dtexp = getdate()

        exec fs_enter_qc 'M', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, 'N/A', 'N/A', 	-- mls 2/26/01 SCR 26061
          @qty, 'N/A', 'N/A', null, @dtexp
      end
    end 

    
    
	
    if @i_produced_qty != 0
    begin
      select @qty =(@i_produced_qty * @i_conv_factor )

      insert prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
        ovhd_dolrs, labor, util_dolrs, tran_date, qty, status,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, tran_id)
      select @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, (@d_unitcost ) , 
        (@d_direct ), (@d_overhead ), 0, 
        (@d_utility ), @apply_date, (@qty * -1), 'N',
        -@a_unitcost, -@a_direct, -@a_overhead, -@a_utility, 0, @a_tran_id

      if @@error > 0
      begin
        rollback tran
        exec adm_raiserror 9910141 ,'Error inserting on prod_list_cost'
        return
      end

      -- Get Accounts
      SELECT @direct_acct = inv_direct_acct_code,
        @ovhd_acct = inv_ovhd_acct_code,
        @util_acct = inv_util_acct_code,
        @inv_acct = inv_acct_code,
        @COGS_acct = ar_cgs_code,
        @COGS_acct_direct = ar_cgs_direct_code,
        @COGS_acct_ovhd = ar_cgs_ovhd_code,
        @COGS_acct_util = ar_cgs_util_code,
        @var_acct      = cost_var_code,
        @var_direct  = cost_var_direct_code,
        @var_ovhd = cost_var_ovhd_code,
        @var_util = cost_var_util_code,
        @wip_acct = wip_acct_code,
        @wip_direct = wip_direct_acct_code,
        @wip_ovhd = wip_ovhd_acct_code,
        @wip_util = wip_util_acct_code
      FROM in_account(nolock)
      WHERE acct_code = @posting_code

      --Inventory Accounts / WIP
      SELECT @iloop = 1

      SELECT @COGS_qty = CASE when @COGS = 2 then abs(@in_stock) when @COGS = 0 then @qty else @qty end

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
             CASE @iloop
             WHEN 1 THEN @a_unitcost WHEN 2 THEN @a_direct WHEN 3 THEN @a_overhead WHEN 4 THEN @a_utility  end,
          @COGS_cost = 
            CASE @iloop
            WHEN 1 THEN @unitcost WHEN 2 THEN @direct WHEN 3 THEN @overhead WHEN 4 THEN @utility end,
          @glaccount = 
             CASE @iloop
             WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct end,
          @wipaccount = 
             CASE @iloop
             WHEN 1 THEN @wip_acct WHEN 2 THEN @wip_direct WHEN 3 THEN @wip_ovhd WHEN 4 THEN @wip_util END,
          @COGSacct =
            case when @COGS = 0 then
              CASE @iloop 
              WHEN 1 THEN @var_acct WHEN 2 THEN @var_direct WHEN 3 THEN @var_ovhd WHEN 4 THEN @var_util end
            else            
              CASE @iloop 
              WHEN 1 THEN @COGS_acct WHEN 2 THEN @COGS_acct_direct WHEN 3 THEN @COGS_acct_ovhd WHEN 4 THEN @COGS_acct_util end
            end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr 
          + case @COGS when 1 then ' (- -)' when 2 then ' (- +)'  when 3 then ' (+ -)' else '' end

        if @COGS_cost <> 0 or @iloop = 1  -- inventory
        begin
          select @tempcost = @COGS_cost / @qty
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@qty,@tempcost,@glaccount,@natcode,DEFAULT,DEFAULT,                                -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @COGS_cost, @iloop 

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting Inventory GL Costing Record!'
            exec adm_raiserror 81331 ,@msg
            return 
          END
        end
        select @line_descr = replace(@line_descr,'inv','wip')
        IF @cost <> 0 		-- wip
        BEGIN
          select @glcost = -@cost
          select @glqty = -@qty 
          select @tempcost = @glcost / @glqty
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@glqty,@tempcost,@wipaccount,@natcode,DEFAULT,DEFAULT,                                -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @glcost, @iloop

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting WIP GL Costing Record!'
            exec adm_raiserror 81331, @msg
            return 
          END
        END 
        if @COGS <> 0 or (@cost != @COGS_cost and charindex(@typ,'123456789') > 0)
        begin
          select @COGS_cost = @cost - @COGS_cost

          if @COGS != 0
            select @line_descr = replace (@line_descr,'wip','ar_cgs'),
				@msg = 'COGS'
          else
            select @line_descr = replace (@line_descr,'wip','cost_var'),
				@msg = 'Cost Variance'

          if @COGS_cost <> 0
          begin 
            select @tempcost = @COGS_cost / @COGS_qty
            exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
              @apply_date,@COGS_qty,@tempcost,@COGSacct,@natcode,DEFAULT,DEFAULT,                        -- mls 6/2/00 SCR 22994
              @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @COGS_cost

            IF @retval != 1 
            BEGIN
              rollback tran
              select @msg = '[' + str(@retval) + '] : Error Inserting GL ' + @msg + ' Costing Record!'
              exec adm_raiserror 81331, @msg
              return 
            END
          end          
        end
        SELECT @iloop = @iloop + 1
      END --While
    END -- produced_qty != 0
  end 	-- direction = 1							-- mls 10/14/99 end
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
  else   -- direction = -1
  begin
    if @company_id is NULL									-- mls 03/30/00 SCR 22716 start
      SELECT @company_id = company_id, @natcode = home_currency 
	FROM glco (nolock)

    select @COGS = 0									-- mls 03/30/00 SCR 22697 start

    select 
      @i_sch_alloc = case when @i_status in ('N','P','Q') and (@i_plan_qty - @i_used_qty) > 0
        THEN ((@i_plan_qty - @i_used_qty) * @i_conv_factor) ELSE 0 end,
      @i_hold_mfg = case when @i_status in ('P','Q') and @i_used_qty != 0
        THEN (@i_used_qty * @i_conv_factor) else 0 end,
      @i_usage_qty = case when @i_status in ('P','Q','R','S')  and @i_used_qty != 0
        THEN (@i_used_qty * @i_conv_factor) else 0 end

    if @i_usage_qty != 0 
    begin
      select @a_tran_qty = @i_used_qty * -1,
        @a_tran_data = isnull(@i_part_type,' ') + isnull(@prod_type,' ') + convert(char(1),@sub_com_cost_ind) +
        convert(char(1),@resource_cost_ind) +
        convert(varchar(30),@i_plan_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_plan_qty))) +
        convert(varchar(30),@i_used_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_used_qty))) +
        convert(varchar(30),0.00) + replicate(' ',30 - datalength(convert(varchar(30),0.00))) 

      exec @retval = adm_inv_tran 
        'U', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_uom, 
        @i_conv_factor, @i_status, @a_tran_data, DEFAULT, 
        @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, 0,
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
      if @retval <> 1
      begin
        rollback tran
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
        exec adm_raiserror 83202, @msg
        RETURN
      end

      select @d_unitcost = @a_unitcost/@i_usage_qty, @d_direct = @a_direct/@i_usage_qty, 
        @d_overhead = @a_overhead/@i_usage_qty, @d_utility = @a_utility/@i_usage_qty
    end

    if (@i_sch_alloc != 0 or @i_hold_mfg != 0 or @i_usage_qty != 0) AND @inv_status not in ('V','!') 	
    begin
      update inv_produce
      set sch_alloc = sch_alloc + @i_sch_alloc,
        hold_mfg = hold_mfg + @i_hold_mfg,
        usage_mtd = usage_mtd + @i_usage_qty,
        usage_ytd = usage_ytd + @i_usage_qty
      where part_no=@i_part_no and location=@i_location

      -- mls 1/18/05 SCR 34050
      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'U', @i_usage_qty
      if @rc < 1
      begin
        select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
        rollback tran
        exec adm_raiserror 9910141, @msg
        return
      end
    end

    if  @i_usage_qty != 0								-- mls 11/29/05 SCR 35782
    begin
      insert prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
        ovhd_dolrs, labor, util_dolrs, tran_date, qty, status,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, tran_id)
      select @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, (-@d_unitcost ) , 
        (-@d_direct ), (-@d_overhead ), 0, 
        (-@d_utility ), @apply_date, (@i_usage_qty ), 'N',                                -- mls 6/2/00 SCR 22994
        -@a_unitcost, -@a_direct , -@a_overhead, -@a_utility, 0, @a_tran_id
      if @@error > 0
      begin
        rollback tran
        exec adm_raiserror 9910141 ,'Error inserting on prod_list_cost'
        return
      end
    end

    if @i_usage_qty != 0 								-- mls 6/1/04 SCR 32861
    begin
      -- Get Accounts
      SELECT @direct_acct = inv_direct_acct_code,
        @ovhd_acct = inv_ovhd_acct_code,
        @util_acct = inv_util_acct_code,
        @inv_acct = inv_acct_code,
        @COGS_acct = ar_cgs_code,
        @COGS_acct_direct = ar_cgs_direct_code,
        @COGS_acct_ovhd = ar_cgs_ovhd_code,
        @COGS_acct_util = ar_cgs_util_code,
        @var_acct      = cost_var_code,
        @var_direct  = cost_var_direct_code,
        @var_ovhd = cost_var_ovhd_code,
        @var_util = cost_var_util_code,
        @wip_acct = wip_acct_code,
        @wip_direct = wip_direct_acct_code,
        @wip_ovhd = wip_ovhd_acct_code,
        @wip_util = wip_util_acct_code
      FROM in_account(nolock)
      WHERE acct_code = @posting_code

      select @glqty = @i_usage_qty

      --Inventory Accounts / AR COGS 
      SELECT @iloop = 1

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
            CASE @iloop
            WHEN 1 THEN (@unitcost )  WHEN 2 THEN (@direct )  
            WHEN 3 THEN (@overhead )  WHEN 4 THEN (@utility ) END,
          @glaccount = 
             CASE @iloop
             WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
          when 3 then ' (+ -)' else '' end

        IF isnull(@cost,0) <> 0 
        BEGIN
          select @tempcost = @cost / @glqty
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no,@i_prod_ext, @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@glqty,@tempcost,@glaccount,@natcode,DEFAULT,DEFAULT,                        -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @cost

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting Inventory GL Costing Record!'
            exec adm_raiserror 991116, @msg
            return 
          END
        END 
        SELECT @iloop = @iloop + 1
      END --While

    if (@COGS <> 0) or 
    (@a_unitcost != @unitcost or @a_overhead != @overhead or @a_direct != @direct or @a_utility != @utility)
    begin
      SELECT @COGS_qty = CASE @COGS WHEN 1 then ( - @i_usage_qty) WHEN 2 then abs(@in_stock)
        WHEN 3 then @in_stock  - @i_usage_qty else ( - @i_usage_qty)  END
      select @glqty = @COGS_qty * -1

      --Inventory Accounts / AR COGS 
      SELECT @iloop = 1

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
            CASE @iloop
            WHEN 1 THEN (@unitcost - @a_unitcost)  WHEN 2 THEN (@direct - @a_direct)  
            WHEN 3 THEN (@overhead - @a_overhead)  WHEN 4 THEN (@utility - @a_utility) END,
          @COGSacct =
            case when @COGS = 0 then
              CASE @iloop 
              WHEN 1 THEN @var_acct WHEN 2 THEN @var_direct WHEN 3 THEN @var_ovhd WHEN 4 THEN @var_util end
            else
              CASE @iloop 
              WHEN 1 THEN @COGS_acct WHEN 2 THEN @COGS_acct_direct WHEN 3 THEN @COGS_acct_ovhd WHEN 4 THEN @COGS_acct_util end
             end,
          @glaccount = 
             CASE @iloop
             WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
          when 3 then ' (+ -)' else '' end

        IF @cost <> 0 
        BEGIN
          select @tempcost = @cost / @glqty
          select @totcost = -@cost, @COGS_qty = -@glqty 
          if @COGS <> 0 
            select @line_descr = replace(@line_descr,'inv','ar_cgs'),
				@msg = 'COGS'
          else
            select @line_descr = replace(@line_descr,'inv','cost_var'),
				@msg = 'Cost Variance'

          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no,@i_prod_ext, @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@COGS_qty,@tempcost,@COGSacct,@natcode,DEFAULT,DEFAULT,                        -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @totcost

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting ' + @msg + ' GL Costing Record!'
            exec adm_raiserror 991116, @msg
            return 
          END
        END 
        SELECT @iloop = @iloop + 1
      END --While
    end -- cogs <> 0                                                        
    end -- @i_usage_qty <> 0
  end -- end of consumed -- direction = -1

  end -- (@i_constrain != 'C' and @i_constrain != 'Y')

FETCH NEXT FROM t700insprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_seq_no, @i_part_no, @i_location, @i_description,
@i_plan_qty, @i_used_qty, @i_attrib, @i_uom, @i_conv_factor, @i_who_entered, @i_note,
@i_lb_tracking, @i_bench_stock, @i_status, @i_constrain, @i_plan_pcs, @i_pieces, @i_scrap_pcs,
@i_part_type, @i_direction, @i_cost_pct, @i_p_qty, @i_p_line, @i_row_id, @i_p_pcs, @i_qc_no,
@i_oper_status, @i_pool_qty, @i_last_tran_date, @i_fixed, @i_active, @i_eff_date, @m_lb_tracking,
@inv_status, @m_qc_flag
end -- while

CLOSE t700insprod_cursor
DEALLOCATE t700insprod_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updprodl] ON [dbo].[prod_list] FOR update AS 
BEGIN

DECLARE @i_prod_no int, @i_prod_ext int, @i_line_no int, @i_seq_no varchar(4),
@i_part_no varchar(30), @i_location varchar(10), @i_description varchar(255),
@i_plan_qty decimal(20,8), @i_used_qty decimal(20,8), @i_attrib decimal(20,8), @i_uom char(2),
@i_conv_factor decimal(20,8), @i_who_entered varchar(20), @i_note varchar(255),
@i_lb_tracking char(1), @i_bench_stock char(1), @i_status char(1), @i_constrain char(1),
@i_plan_pcs decimal(20,8), @i_pieces decimal(20,8), @i_scrap_pcs decimal(20,8),
@i_part_type char(1), @i_direction int, @i_cost_pct decimal(20,8), @i_p_qty decimal(20,8),
@i_p_line int, @i_row_id int, @i_p_pcs decimal(20,8), @i_qc_no int, @i_oper_status char(1),
@i_pool_qty decimal(20,8), @i_last_tran_date datetime, @i_fixed char(1), @i_active char(1),
@i_eff_date datetime,
@d_prod_no int, @d_prod_ext int, @d_line_no int, @d_seq_no varchar(4),
@d_part_no varchar(30), @d_location varchar(10), @d_description varchar(255),
@d_plan_qty decimal(20,8), @d_used_qty decimal(20,8), @d_attrib decimal(20,8), @d_uom char(2),
@d_conv_factor decimal(20,8), @d_who_entered varchar(20), @d_note varchar(255),
@d_lb_tracking char(1), @d_bench_stock char(1), @d_status char(1), @d_constrain char(1),
@d_plan_pcs decimal(20,8), @d_pieces decimal(20,8), @d_scrap_pcs decimal(20,8),
@d_part_type char(1), @d_direction int, @d_cost_pct decimal(20,8), @d_p_qty decimal(20,8),
@d_p_line int, @d_row_id int, @d_p_pcs decimal(20,8), @d_qc_no int, @d_oper_status char(1),
@d_pool_qty decimal(20,8), @d_last_tran_date datetime, @d_fixed char(1), @d_active char(1),
@d_eff_date datetime

DECLARE @inv_status char(1), @prod_type char(1), @posting_code varchar(8),
  @apply_date datetime, @company_id int, @COGS int, @fg_cost_ind int, @prod_date datetime,
  @natcode varchar(8), @sub_com_cost_ind int, @resource_cost_ind int, @a_tran_qty decimal(20,8),
  @d_produced_qty decimal(20,8), @i_produced_qty decimal(20,8), @d_hold_mfg decimal(20,8),
  @i_hold_mfg decimal(20,8), @a_tran_data varchar(255), @retval int, @a_tran_id int,
  @a_unitcost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_utility decimal(20,8), @a_labor decimal(20,8),
  @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8), @d_utility decimal(20,8),
  @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8), @labor decimal(20,8),
  @in_stock decimal(20,8), @qty decimal(20,8), @lot varchar(25), @bin varchar(12),
  @dtexp datetime, 
  @direct_acct varchar(32), @ovhd_acct varchar(32), @util_acct varchar(32), @inv_acct varchar(32), 
  @COGS_acct varchar(32), @COGS_acct_direct varchar(32), @COGS_acct_ovhd varchar(32), @COGS_acct_util varchar(32), 
  @wip_acct varchar(32), @wip_direct varchar(32), @wip_ovhd varchar(32), @wip_util varchar(32), 
  @var_acct varchar(32), @var_direct varchar(32), @var_ovhd varchar(32), @var_util varchar(32), 
  @iloop int, @COGS_qty decimal(20,8), @cost decimal(20,8), @COGS_cost decimal(20,8),
  @glaccount varchar(32), @wipaccount varchar(32), @COGSacct varchar(32), @line_descr varchar(50),
  @glcost decimal(20,8), @glqty decimal(20,8),
  @d_sch_alloc decimal(20,8), @i_sch_alloc decimal(20,8), @i_usage_qty decimal(20,8), @d_usage_qty decimal(20,8), 
  @msg varchar(255), @m_qc_flag char(1), @totcost decimal(20,8), @tempcost decimal(20,8),
  @typ char(1)

declare @m_lb_tracking char(1), @m_status char(1),
@lb_sum decimal(20,8), @uom_sum decimal(20,8), @part_cnt int, @lb_part varchar(30), @lb_loc varchar(10),
@inv_lot_bin int, @used_qty decimal(20,8),
@rc int, @mtd_qty decimal(20,8)

DECLARE t700updprod_cursor CURSOR LOCAL STATIC FOR
SELECT i.prod_no, i.prod_ext, i.line_no, i.seq_no, i.part_no, i.location, i.description,
i.plan_qty, i.used_qty, i.attrib, i.uom, i.conv_factor, i.who_entered, i.note, i.lb_tracking,
i.bench_stock, i.status, i.constrain, i.plan_pcs, i.pieces, i.scrap_pcs, i.part_type,
i.direction, i.cost_pct, i.p_qty, i.p_line, i.row_id, i.p_pcs, i.qc_no, i.oper_status,
i.pool_qty, i.last_tran_date, i.fixed, i.active, i.eff_date,
d.prod_no, d.prod_ext, d.line_no, d.seq_no, d.part_no, d.location, d.description,
d.plan_qty, d.used_qty, d.attrib, d.uom, d.conv_factor, d.who_entered, d.note, d.lb_tracking,
d.bench_stock, d.status, d.constrain, d.plan_pcs, d.pieces, d.scrap_pcs, d.part_type,
d.direction, d.cost_pct, d.p_qty, d.p_line, d.row_id, d.p_pcs, d.qc_no, d.oper_status,
d.pool_qty, d.last_tran_date, d.fixed, d.active, d.eff_date,
m.lb_tracking, m.status, m.qc_flag
from inserted i
join deleted d on i.row_id=d.row_id
left outer join inv_master m on m.part_no = i.part_no

OPEN t700updprod_cursor

if @@cursor_rows = 0
begin
  CLOSE t700updprod_cursor
  DEALLOCATE t700updprod_cursor
  return
end

FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_seq_no, @i_part_no, @i_location, @i_description,
@i_plan_qty, @i_used_qty, @i_attrib, @i_uom, @i_conv_factor, @i_who_entered, @i_note,
@i_lb_tracking, @i_bench_stock, @i_status, @i_constrain, @i_plan_pcs, @i_pieces, @i_scrap_pcs,
@i_part_type, @i_direction, @i_cost_pct, @i_p_qty, @i_p_line, @i_row_id, @i_p_pcs, @i_qc_no,
@i_oper_status, @i_pool_qty, @i_last_tran_date, @i_fixed, @i_active, @i_eff_date,
@d_prod_no, @d_prod_ext, @d_line_no, @d_seq_no, @d_part_no, @d_location, @d_description,
@d_plan_qty, @d_used_qty, @d_attrib, @d_uom, @d_conv_factor, @d_who_entered, @d_note,
@d_lb_tracking, @d_bench_stock, @d_status, @d_constrain, @d_plan_pcs, @d_pieces, @d_scrap_pcs,
@d_part_type, @d_direction, @d_cost_pct, @d_p_qty, @d_p_line, @d_row_id, @d_p_pcs, @d_qc_no,
@d_oper_status, @d_pool_qty, @d_last_tran_date, @d_fixed, @d_active, @d_eff_date,
@m_lb_tracking, @inv_status, @m_qc_flag

While @@FETCH_STATUS = 0
begin
  select @msg = ''
  if @i_part_no != @d_part_no 
    select @msg = 'You Cannot change part number on a prod_list line'
  else if @i_location != @d_location
    select @msg = 'You Cannot change location on a prod_list line'
  else if @i_prod_no != @d_prod_no or @i_prod_ext != @d_prod_ext
    select @msg = 'You Cannot change production number on a prod_list line'
  else if @i_line_no != @d_line_no
    select @msg = 'You Cannot change line number on a prod_list line'

  if @msg <> ''
  begin
    rollback tran 
    exec adm_raiserror 96131, @msg
    return
  end

  if @i_qc_no > 0 and @i_status in ('S','V')
  begin
    rollback tran 
    exec adm_raiserror 96131 ,'You Cannot Post Finished Production With QC Pending!'
    return
  end

  IF @i_part_type != 'X'                                                                         -- mls 03/30/00 SCR 22716
  begin                                                                                                -- mls 03/30/00 SCR 22716
    if @m_lb_tracking is null
    begin
      rollback tran
      exec adm_raiserror 832111, 'Part does not exists in inventory.'
      RETURN
    end

    if not exists (select 1 from inv_produce (nolock)
    WHERE  part_no =  @i_part_no AND location =  @i_location)
    BEGIN
      rollback tran
      exec adm_raiserror 96132 ,'Inventory Part Missing.  The transaction is being rolled back.'
      RETURN
    END
  END
  ELSE
    select @inv_status = '!'

  if isnull(@m_lb_tracking,'N') != @i_lb_tracking
  begin
    rollback tran
    exec adm_raiserror 832112, 'Lot bin tracking flag mismatch with inventory.'
    RETURN
  end

  if @inv_lot_bin is null
    select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)

  select @lb_sum = sum(qty * direction),
    @uom_sum = sum(uom_qty * direction),
    @part_cnt = count(distinct (part_no + '!@#' + location)) ,
    @lb_part = min(part_no),
    @lb_loc = min(location)
  from lot_bin_prod (nolock)
  where tran_no = @i_prod_no and tran_ext = @i_prod_ext and line_no = @i_line_no

  select @used_qty = (@i_used_qty - case when @i_direction > 0 then @i_scrap_pcs else 0 end) * @i_direction
  select @lb_sum = isnull(@lb_sum,0), @uom_sum = isnull(@uom_sum,0), @part_cnt = isnull(@part_cnt,0),
    @lb_part = isnull(@lb_part,''), @lb_loc = isnull(@lb_loc,'')

  if isnull(@m_lb_tracking,'') = 'Y' 
  begin
    if @inv_lot_bin = 1
    begin
      if @part_cnt > 1
      begin
        rollback tran
        exec adm_raiserror 832113 ,'More than one parts lot bin records found on lot_bin_prod for this prod_line.'
        RETURN
      end
      if @uom_sum != @used_qty
      begin
        select @msg = 'Prod Line uom qty of ([' + convert(varchar,@used_qty) + ']) does not equal the lot and bin uom qty of ([' + convert(varchar,@uom_sum) + ']).'
        rollback tran
        exec adm_raiserror 832113 ,@msg
        RETURN
      end
      if @lb_sum != (@used_qty * @i_conv_factor)
      begin
        select @msg = 'Prod Line qty of ([' + convert(varchar,(@used_qty * @i_conv_factor)) + ']) does not equal the lot and bin qty of ([' + convert(varchar,@lb_sum) + ']).'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      if @part_cnt > 0 and ( @lb_part != @i_part_no or @lb_loc != @i_location)
      begin
        select @msg = 'Part/Location on lot_bin_prod is not the same as on prod_list table.'
        rollback tran
        exec adm_raiserror 832115, @msg
        RETURN
      end
    end
    else
    begin
      if @part_cnt > 0
      begin
        select @msg = 'You cannot have lot bin records on an production transaction when you are not lb tracking.'
        rollback tran
        exec adm_raiserror 832114, @msg
        RETURN
      end
    end
  end
  else
  begin
    if @part_cnt > 0
    begin
      rollback tran
      exec adm_raiserror 832114,'Lot bin records found on lot_bin_prod for this not lot/bin tracked part.'
      RETURN
    end
  end


  if @i_direction > 0 and (abs(@i_used_qty) - abs(@i_scrap_pcs)) < 0
  begin
    rollback tran 
    exec adm_raiserror 96133 ,'Scrap Can NOT Exceed Quantity Produced!'
    return
  end

  if exists (select 1 from produce_all (nolock)
    where prod_no = @i_prod_no and prod_ext = @i_prod_ext and hold_flag='Y') 
  begin
    rollback tran 
    exec adm_raiserror 96134, 'You Can Not Modify A Held Production Order.'
    return
  end

  if (@i_constrain != 'C' and @i_constrain != 'Y')
  begin
    if (@i_direction != @d_direction)
    begin
      rollback tran 
      exec adm_raiserror 991014, 'You Can Not make a component the finished good or vice versa.'
      return
    end                                                                                                        -- mls 10/14/99 end

    if (@i_part_no != @d_part_no or @i_location != @d_location)
    begin
      rollback tran 
      exec adm_raiserror 991014 ,'You Can Not change the part number or location on an item.'
      return
    end                                                                                                        -- mls 10/14/99 end

    select @prod_type = p.prod_type,                                                                         
      @fg_cost_ind = isnull(p.fg_cost_ind,0),                                                                -- mls 03/30/00 SCR 22697 start
      @sub_com_cost_ind = isnull(sub_com_cost_ind,0), 
      @resource_cost_ind = isnull(resource_cost_ind,0),
      @prod_date = isnull(prod_date,getdate())                                                                -- mls 03/30/00 SCR 22697 end                        
    from produce_all p (nolock)
    where p.prod_no = @i_prod_no and p.prod_ext = @i_prod_ext                                                

    if @inv_status = '!' and @i_direction = -1 and @prod_type = 'J'                                        -- mls 4/17/01 SCR 26742 start
    begin
      SELECT @posting_code = l.aracct_code
      from locations_all l (nolock) where location = @i_location
    end
    else
    begin                                                                                                -- mls 4/17/01 SCR 26742 end
      SELECT @posting_code = l.acct_code
      from inv_list l
      WHERE l.part_no = @i_part_no AND l.location = @i_location

      if @@rowcount = 0                                                                                -- mls 10/14/99 start
      begin
        rollback tran
        exec adm_raiserror 9910142, 'Part does not exist in inventory'
        return
      end                                                                                                -- mls 10/14/99 end
    end
        
  -- MLS 3/30/00 SCR 22697
  -- NOTE: fg_cost_ind determines which cost to use for the finished good in reverse manufacturing. If the
  -- ind = 0 then use the current costs.  If the ind != 0 then use the cost from the production that is being reversed.
  -- sub_com_cost_ind determines which cost to use for the subcomponent costs in reverse manufacturing.  If the
  -- ind = 0 then use the current costs.  If the ind != 0 then use the cost from the production that is being reversed.
  -- resource_ind determins whether the resource costs are going to be reversed on a reversal.  If the ind = 0
  -- then the costs will be reversed.  If the ind != 0 then the costs will not be reversed.

  select @apply_date = isnull(@i_last_tran_date,@prod_date)                                                -- mls 12/30/03 SCR 32112
													 -- mls 4/13/00 SCR 22566 

  if @i_direction = 1        -- Finished Good                                                                        -- mls 10/14/99 start
  begin
    if @company_id is NULL        
      SELECT @company_id = company_id, @natcode = home_currency FROM glco (nolock)

    SELECT @COGS = 0
    select @a_tran_qty = 0

    select 
      @d_produced_qty = 
        case when (@d_status in ('P','Q') and @prod_type = 'R') or @d_status = 'S' 
          then (@d_used_qty - @d_scrap_pcs) * @d_conv_factor else 0 end,
      @i_produced_qty = 
        case when (@i_status in ('P','Q') and @prod_type = 'R') or @i_status = 'S' 
          then (@i_used_qty - @i_scrap_pcs) * @i_conv_factor else 0 end,
      @d_hold_mfg =
        case when (@d_status in ('P','Q') and @prod_type !='R') or @d_status = 'R' 
          then (@d_used_qty - @d_scrap_pcs) * @d_conv_factor else 0 end,
      @i_hold_mfg =
        case when (@i_status in ('P','Q') and @prod_type !='R') or @i_status = 'R' 
          then (@i_used_qty - @i_scrap_pcs) * @i_conv_factor else 0 end

    if @d_produced_qty != @i_produced_qty or @d_hold_mfg != @i_hold_mfg 
    begin
      if (@i_produced_qty != 0 or @d_produced_qty != 0)
        select @a_tran_qty = @i_produced_qty - @d_produced_qty
      else  
        select @a_tran_qty = @i_hold_mfg  - @d_hold_mfg 
         
      select @a_tran_qty = @a_tran_qty / @i_conv_factor,
        @a_tran_data = isnull(@prod_type,' ') + convert(char(1),@fg_cost_ind) +
        convert(varchar(30),@i_cost_pct) + replicate(' ',30 - datalength(convert(varchar(30),@i_cost_pct))) +
        convert(varchar(30),@i_plan_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_plan_qty))) +
        convert(varchar(30),@i_used_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_used_qty))) 

      exec @retval = adm_inv_tran 
        'P', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_uom, 
        @i_conv_factor, @i_status, @a_tran_data, DEFAULT, 
        @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT,
        @typ OUT
      if @retval <> 1
      begin
        rollback tran
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
        exec adm_raiserror 83202,@msg
        RETURN
      end
      select @d_unitcost = @a_unitcost / @a_tran_qty, @d_direct = @a_direct/ @a_tran_qty,
        @d_overhead = @a_overhead/ @a_tran_qty, @d_utility = @a_utility/ @a_tran_qty

      update inv_produce set 
        hold_mfg = hold_mfg + @i_hold_mfg - @d_hold_mfg,
        produced_mtd = produced_mtd + @i_produced_qty - @d_produced_qty,
        produced_ytd = produced_ytd + @i_produced_qty - @d_produced_qty
      where part_no= @d_part_no and location = @d_location 

      -- mls 1/18/05 SCR 34050
      select @mtd_qty = (@i_produced_qty - @d_produced_qty)
      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'P', @mtd_qty
      if @rc < 1
      begin
        select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
        rollback tran
        exec adm_raiserror 9910141 ,@msg
        return
      end
    end

    if @i_lb_tracking = 'Y'
    begin
      if exists (select 1 from lot_bin_prod l (nolock) where l.tran_no = @i_prod_no and                -- mls 03/30/00 SCR 22716 start
      l.tran_ext = @i_prod_ext and l.line_no = @i_line_no and l.part_no = @i_part_no and                
      l.tran_code <> @i_status)                                                                        -- mls 03/30/00 SCR 22716 end
      begin
        update lot_bin_prod
        set tran_code =  @i_status
        where tran_no = @i_prod_no and tran_ext = @i_prod_ext and 
          line_no = @i_line_no and part_no = @i_part_no and
          tran_code <> @i_status 
      end
    end

    
    if @i_status = 'R' and @i_hold_mfg != 0 and @i_qc_no = 0 
    begin
      if isnull(@m_qc_flag,'N') = 'Y'
      begin
        select @qty=(@i_hold_mfg * @i_conv_factor),
          @lot = 'N/A', @bin = 'N/A', @dtexp = getdate()

        exec fs_enter_qc 'M', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, @lot, @bin,         -- mls 2/23/01 SCR 26060
          @qty, 'N/A', 'N/A', null, @dtexp
      end 
    end

    
    select @a_tran_qty = (@i_produced_qty * @i_conv_factor) - (@d_produced_qty * @d_conv_factor)
    if @a_tran_qty != 0
    begin
      select @qty = @a_tran_qty

      insert prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
        ovhd_dolrs, labor, util_dolrs, tran_date, qty, status,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, tran_id)
      select @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, (@d_unitcost ) , 
        (@d_direct ), (@d_overhead ), 0, 
        (@d_utility ), @apply_date, (@qty * -1), 'N',                                -- mls 3/6/00 SCR 22566
        -@a_unitcost, -@a_direct, -@a_overhead, -@a_utility, 0, @a_tran_id

      if @@error > 0
      begin
        rollback tran
        exec adm_raiserror 9910141, 'Error inserting on prod_list_cost'
        return
      end

      -- Get Accounts
      SELECT @direct_acct = inv_direct_acct_code,
        @ovhd_acct = inv_ovhd_acct_code,
        @util_acct = inv_util_acct_code,
        @inv_acct = inv_acct_code,
        @COGS_acct = ar_cgs_code,
        @COGS_acct_direct = ar_cgs_direct_code,
        @COGS_acct_ovhd = ar_cgs_ovhd_code,
        @COGS_acct_util = ar_cgs_util_code,
        @var_acct      = cost_var_code,
        @var_direct  = cost_var_direct_code,
        @var_ovhd = cost_var_ovhd_code,
        @var_util = cost_var_util_code,
        @wip_acct = wip_acct_code,
        @wip_direct = wip_direct_acct_code,
        @wip_ovhd = wip_ovhd_acct_code,
        @wip_util = wip_util_acct_code
      FROM in_account(nolock)
      WHERE acct_code = @posting_code

      --Inventory Accounts / WIP
      SELECT @iloop = 1

      SELECT @COGS_qty = CASE when @COGS = 2 then abs(@in_stock) when @COGS = 0 then @qty else @qty end

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
            CASE @iloop
            WHEN 1 THEN @a_unitcost WHEN 2 THEN @a_direct WHEN 3 THEN @a_overhead WHEN 4 THEN @a_utility end,
          @COGS_cost = 
            CASE @iloop
            WHEN 1 THEN @unitcost WHEN 2 THEN @direct WHEN 3 THEN @overhead WHEN 4 THEN @utility end,
          @glaccount = 
            CASE @iloop
            WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
          @wipaccount = 
            CASE @iloop
            WHEN 1 THEN @wip_acct WHEN 2 THEN @wip_direct WHEN 3 THEN @wip_ovhd WHEN 4 THEN @wip_util END,
          @COGSacct =
            case when @COGS = 0 then
              CASE @iloop 
              WHEN 1 THEN @var_acct WHEN 2 THEN @var_direct WHEN 3 THEN @var_ovhd WHEN 4 THEN @var_util end
            else            
              CASE @iloop 
              WHEN 1 THEN @COGS_acct WHEN 2 THEN @COGS_acct_direct WHEN 3 THEN @COGS_acct_ovhd WHEN 4 THEN @COGS_acct_util end
            end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
          when 3 then ' (+ -)' else '' end

        if @COGS_cost != 0 or @iloop = 1	-- inventory
        begin
          select @glcost = @COGS_cost / @qty 
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@qty,@glcost,@glaccount,@natcode,DEFAULT,DEFAULT,                                -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @COGS_cost, @iloop 

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting Inventory GL Costing Record!'
            exec adm_raiserror 81331, @msg
            return 
          END
        end
       
        select @line_descr = replace(@line_descr,'inv','wip')
        if @cost != 0  -- wip
        begin
          select @totcost = -@cost 
          select @tempcost = @cost / @qty
          select @glqty = @qty * -1
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@glqty,@tempcost,@wipaccount,@natcode,DEFAULT,DEFAULT,                                -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr,@totcost 

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting WIP GL Costing Record!'
            exec adm_raiserror 81331, @msg
            return 
          END
        end

        if @COGS != 0 or (@cost != @COGS_cost and charindex(@typ,'123456789') > 0)
        begin
          select @COGS_cost = @cost - @COGS_cost
          if @COGS != 0
            select @line_descr = replace(@line_descr,'wip','ar_cgs'),
				@msg = 'COGS'
          else
            select @line_descr = replace(@line_descr,'wip','cost_var'),
				@msg = 'Cost Variance'

          if @COGS_cost != 0 
          begin
            select @tempcost = @COGS_cost / @COGS_qty
            
            exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no, @i_prod_ext , @i_line_no,        -- mls 1/24/01 SCR 20787
              @apply_date,@COGS_qty,@tempcost,@COGSacct,@natcode,DEFAULT,DEFAULT,                                -- mls 6/2/00 SCR 22994
              @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr , @COGS_cost

            IF @retval != 1 
            BEGIN
              rollback tran
              select @msg = '[' + str(@retval) + '] : Error Inserting ' + @msg + ' GL Costing Record!'
              exec adm_raiserror 81331, @msg
              return 
            END
          end
        end

        SELECT @iloop = @iloop + 1
      END --While
    END -- a_tran_qty != 0
  end                                                                                         -- mls 10/14/99 end
-------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------
  else 
  begin
    if @company_id is NULL                                                                        -- mls 03/30/00 SCR 22716 start
      SELECT @company_id = company_id, @natcode = home_currency FROM glco (nolock)

    select @COGS = 0, @a_tran_qty = 0                                                                                -- mls 03/30/00 SCR 22697 start

    select 
      @d_sch_alloc = case when @d_status in ('N','P','Q') and (@d_plan_qty - @d_used_qty) > 0
        THEN ((@d_plan_qty - @d_used_qty) * @d_conv_factor) ELSE 0 end,
      @d_hold_mfg = case when @d_status in ('P','Q') and @d_used_qty != 0
        THEN (@d_used_qty * @d_conv_factor) else 0 end,
      @d_usage_qty = case when @d_status in ('P','Q','R','S')  and @d_used_qty != 0
        THEN (@d_used_qty * @d_conv_factor) else 0 end,
      @i_sch_alloc = case when @i_status in ('N','P','Q') and (@i_plan_qty - @i_used_qty) > 0
        THEN ((@i_plan_qty - @i_used_qty) * @i_conv_factor) ELSE 0 end,
      @i_hold_mfg = case when @i_status in ('P','Q') and @i_used_qty != 0
        THEN (@i_used_qty * @i_conv_factor) else 0 end,
      @i_usage_qty = case when @i_status in ('P','Q','R','S')  and @i_used_qty != 0
        THEN (@i_used_qty * @i_conv_factor) else 0 end

    if @i_usage_qty != @d_usage_qty
    begin
      select @a_tran_qty = @i_usage_qty - @d_usage_qty

      select @a_tran_qty = (@a_tran_qty / @i_conv_factor) ,
        @a_tran_data = isnull(@i_part_type,' ') + isnull(@prod_type,' ') + convert(char(1),@sub_com_cost_ind) +
        convert(char(1),case when @i_usage_qty > 0 or @i_plan_qty > 0 then 1 else @resource_cost_ind end) +
        convert(varchar(30),@i_plan_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_plan_qty))) +
        convert(varchar(30),@i_used_qty) + replicate(' ',30 - datalength(convert(varchar(30),@i_used_qty))) +
        convert(varchar(30),@d_used_qty) + replicate(' ',30 - datalength(convert(varchar(30),@d_used_qty))) 

      select @a_tran_qty = @a_tran_qty * -1

      exec @retval = adm_inv_tran 
        'U', @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, @i_location, @a_tran_qty, @apply_date, @i_uom, 
        @i_conv_factor, @i_status, @a_tran_data, DEFAULT, 
        @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT ,
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT,
        @typ OUT

      if @retval <> 1
      begin
        rollback tran
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
        exec adm_raiserror 83202, @msg
        RETURN
      end

      select @d_unitcost = @a_unitcost / @a_tran_qty, @d_direct = @a_direct / @a_tran_qty, 
        @d_overhead = @a_overhead / @a_tran_qty, @d_utility = @a_utility / @a_tran_qty
    end

    if (@i_sch_alloc != @d_sch_alloc or @i_hold_mfg != @d_hold_mfg or @i_usage_qty != @d_usage_qty) AND @inv_status not in ('V','!') 	
    begin
      update inv_produce
      set sch_alloc = sch_alloc + @i_sch_alloc - @d_sch_alloc,
        hold_mfg = hold_mfg + @i_hold_mfg - @d_hold_mfg,
        usage_mtd = usage_mtd + @i_usage_qty - @d_usage_qty,
        usage_ytd = usage_ytd + @i_usage_qty - @d_usage_qty
      where part_no=@i_part_no and location=@i_location

      -- mls 1/18/05 SCR 34050
      select @mtd_qty = (@i_usage_qty - @d_usage_qty)
      exec @rc = adm_inv_mtd_upd @i_part_no, @i_location, 'U', @mtd_qty
      if @rc < 1
      begin
        select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
        rollback tran
        exec adm_raiserror 9910141, @msg
        return
      end
    end
    if (@i_usage_qty - @d_usage_qty) != 0
    begin
      insert prod_list_cost (prod_no, prod_ext, line_no, part_no, cost, direct_dolrs,
        ovhd_dolrs, labor, util_dolrs, tran_date, qty, status,
        tot_mtrl_cost, tot_dir_cost, tot_ovhd_cost, tot_util_cost, tot_labor_cost, tran_id)
      select @i_prod_no, @i_prod_ext, @i_line_no, @i_part_no, (@d_unitcost ) , 
        (@d_direct ), (@d_overhead ), 0, 
        (@d_utility ), @apply_date, (@i_usage_qty - @d_usage_qty), 'N' ,
        -@a_unitcost, -@a_direct, -@a_overhead, -@a_utility, 0, @a_tran_id

      if @@error > 0
      begin
        rollback tran
        exec adm_raiserror 9910141, 'Error inserting on prod_list_cost'
        return
      end
    end

    if @a_tran_qty != 0											-- mls 5/24/04 SCR 32407
    begin
      if @i_part_type = 'R' and @a_tran_qty > 0  							-- mls 8/6/07
      begin
        select @unitcost = -@unitcost, @direct = -@direct,
          @overhead = -@overhead, @utility = -@utility
      end

      -- Get Accounts
      SELECT @direct_acct = inv_direct_acct_code,
        @ovhd_acct = inv_ovhd_acct_code,
        @util_acct = inv_util_acct_code,
        @inv_acct = inv_acct_code,
        @COGS_acct = ar_cgs_code,
        @COGS_acct_direct = ar_cgs_direct_code,
        @COGS_acct_ovhd = ar_cgs_ovhd_code,
        @COGS_acct_util = ar_cgs_util_code,
        @var_acct      = cost_var_code,
        @var_direct  = cost_var_direct_code,
        @var_ovhd = cost_var_ovhd_code,
        @var_util = cost_var_util_code,
        @wip_acct = wip_acct_code,
        @wip_direct = wip_direct_acct_code,
        @wip_ovhd = wip_ovhd_acct_code,
        @wip_util = wip_util_acct_code
      FROM in_account(nolock)
      WHERE acct_code = @posting_code

      SELECT @glqty = (@d_usage_qty - @i_usage_qty)
      --Inventory Accounts / AR COGS 
      SELECT @iloop = 1

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
            CASE @iloop
            WHEN 1 THEN (@unitcost )  WHEN 2 THEN (@direct )  
            WHEN 3 THEN (@overhead )  WHEN 4 THEN (@utility ) END,
          @glaccount = 
             CASE @iloop
             WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
          when 3 then ' (+ -)' else '' end

        IF @cost <> 0 
        BEGIN
          select @tempcost = @cost / @glqty
          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no,@i_prod_ext, @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@glqty,@tempcost,@glaccount,@natcode,DEFAULT,DEFAULT,                        -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr, @cost

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting Inventory GL Costing Record!'
            exec adm_raiserror 991116, @msg
            return 
          END
        END 
        SELECT @iloop = @iloop + 1
      END --While

    if (@COGS <> 0) or 
    (@a_unitcost != @unitcost or @a_overhead != @overhead or @a_direct != @direct or @a_utility != @utility)
    begin
      SELECT @COGS_qty = CASE @COGS WHEN 1 then (@d_usage_qty - @i_usage_qty) WHEN 2 then abs(@in_stock)
        WHEN 3 then @in_stock + (@d_usage_qty - @i_usage_qty) else (@d_usage_qty - @i_usage_qty)  END
      select @glqty = @COGS_qty * -1
      --Inventory Accounts / AR COGS 
      SELECT @iloop = 1

      WHILE @iloop <= 4
      BEGIN 
        Select 
          @cost = 
            CASE @iloop
            WHEN 1 THEN (@unitcost - @a_unitcost)  WHEN 2 THEN (@direct - @a_direct)  
            WHEN 3 THEN (@overhead - @a_overhead)  WHEN 4 THEN (@utility - @a_utility) END,
          @COGSacct =
            case when @COGS = 0 then
              CASE @iloop 
              WHEN 1 THEN @var_acct WHEN 2 THEN @var_direct WHEN 3 THEN @var_ovhd WHEN 4 THEN @var_util end
            else
              CASE @iloop 
              WHEN 1 THEN @COGS_acct WHEN 2 THEN @COGS_acct_direct WHEN 3 THEN @COGS_acct_ovhd WHEN 4 THEN @COGS_acct_util end
             end,
          @line_descr = 
             CASE @iloop
             WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' WHEN 4 THEN 'inv_util_acct' END

        select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' 
          when 3 then ' (+ -)' else '' end

        IF @cost <> 0 
        BEGIN
          select @tempcost = @cost / @glqty
          select @totcost = -@cost

          if @COGS <> 0 
            select @line_descr = replace(@line_descr,'inv','ar_cgs'),
              @msg = 'COGS'
          else
            select @line_descr = replace(@line_descr,'inv','cost_var'),
              @msg = 'Cost Variance'

          exec @retval = adm_gl_insert @i_part_no ,@i_location,'P',@i_prod_no,@i_prod_ext, @i_line_no,        -- mls 1/24/01 SCR 20787
            @apply_date,@COGS_qty,@tempcost,@COGSacct,@natcode,DEFAULT,DEFAULT,                        -- mls 6/2/00 SCR 22994
            @company_id, DEFAULT, DEFAULT, @a_tran_id, @line_descr,@totcost

          IF @retval != 1 
          BEGIN
            rollback tran
            select @msg = '[' + str(@retval) + '] : Error Inserting ' + @msg + ' GL Costing Record!'
            exec adm_raiserror 991116, @msg
            return 
          END
        END 
        SELECT @iloop = @iloop + 1
      END --While

    end -- cogs <> 0                                                        
    end -- a_tran_qty != 0										-- mls 5/24/04 SCR 32407
  end 

  if @i_status = 'V' and @i_lb_tracking = 'Y'
  begin
    if exists (select 1 from lot_bin_prod l (nolock) where l.tran_no = @i_prod_no and                -- mls 03/30/00 SCR 22716 start
      l.tran_ext = @i_prod_ext and l.line_no = @i_line_no and l.part_no = @i_part_no)
    begin
      delete lot_bin_prod 
      where tran_no=@i_prod_no and tran_ext= @i_prod_ext and line_no=@i_line_no and 
        part_no=@i_part_no
    end                                                                                                -- mls 03/30/00 SCR 22716 end
  end   
  end 

  
  if @i_part_type = '+'
    exec fs_expand_plist @i_prod_no, @i_prod_ext, @i_line_no

FETCH NEXT FROM t700updprod_cursor into
@i_prod_no, @i_prod_ext, @i_line_no, @i_seq_no, @i_part_no, @i_location, @i_description,
@i_plan_qty, @i_used_qty, @i_attrib, @i_uom, @i_conv_factor, @i_who_entered, @i_note,
@i_lb_tracking, @i_bench_stock, @i_status, @i_constrain, @i_plan_pcs, @i_pieces, @i_scrap_pcs,
@i_part_type, @i_direction, @i_cost_pct, @i_p_qty, @i_p_line, @i_row_id, @i_p_pcs, @i_qc_no,
@i_oper_status, @i_pool_qty, @i_last_tran_date, @i_fixed, @i_active, @i_eff_date,
@d_prod_no, @d_prod_ext, @d_line_no, @d_seq_no, @d_part_no, @d_location, @d_description,
@d_plan_qty, @d_used_qty, @d_attrib, @d_uom, @d_conv_factor, @d_who_entered, @d_note,
@d_lb_tracking, @d_bench_stock, @d_status, @d_constrain, @d_plan_pcs, @d_pieces, @d_scrap_pcs,
@d_part_type, @d_direction, @d_cost_pct, @d_p_qty, @d_p_line, @d_row_id, @d_p_pcs, @d_qc_no,
@d_oper_status, @d_pool_qty, @d_last_tran_date, @d_fixed, @d_active, @d_eff_date,
@m_lb_tracking, @inv_status, @m_qc_flag
end -- while

CLOSE t700updprod_cursor
DEALLOCATE t700updprod_cursor

END
GO
ALTER TABLE [dbo].[prod_list] ADD CONSTRAINT [prod_list_active_cc1] CHECK (([active]='F' OR [active]='T' OR [active]='M' OR [active]='V' OR [active]='U' OR [active]='B' OR [active]='A'))
GO
ALTER TABLE [dbo].[prod_list] ADD CONSTRAINT [prod_list_fixed_cc1] CHECK (([fixed]='N' OR [fixed]='Y'))
GO
CREATE NONCLUSTERED INDEX [prod_list3] ON [dbo].[prod_list] ([part_no], [location], [direction]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [prod_list2] ON [dbo].[prod_list] ([prod_no], [prod_ext], [constrain], [status]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [prodlst1] ON [dbo].[prod_list] ([prod_no], [prod_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [prod_list5] ON [dbo].[prod_list] ([prod_no], [prod_ext], [seq_no], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [prod_list4] ON [dbo].[prod_list] ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[prod_list] TO [public]
GO
GRANT SELECT ON  [dbo].[prod_list] TO [public]
GO
GRANT INSERT ON  [dbo].[prod_list] TO [public]
GO
GRANT DELETE ON  [dbo].[prod_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[prod_list] TO [public]
GO
