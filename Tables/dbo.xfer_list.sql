CREATE TABLE [dbo].[xfer_list]
(
[timestamp] [timestamp] NOT NULL,
[xfer_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[from_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[to_loc] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[time_entered] [datetime] NOT NULL,
[ordered] [decimal] (20, 8) NOT NULL,
[shipped] [decimal] (20, 8) NOT NULL,
[comment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 8) NOT NULL,
[com_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temp_cost] [decimal] (20, 8) NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[std_cost] [decimal] (20, 8) NOT NULL,
[from_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_expires] [datetime] NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[labor] [decimal] (20, 8) NOT NULL,
[direct_dolrs] [decimal] (20, 8) NOT NULL,
[ovhd_dolrs] [decimal] (20, 8) NOT NULL,
[util_dolrs] [decimal] (20, 8) NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[display_line] [int] NULL CONSTRAINT [DF__xfer_list__displ__55B694C8] DEFAULT ((0)),
[qty_rcvd] [decimal] (20, 8) NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adj_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[amt_variance] [decimal] (20, 8) NULL CONSTRAINT [DF__xfer_list__amt_v__56AAB901] DEFAULT ((0)),
[back_ord_flag] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t602delxferl] ON [dbo].[xfer_list] FOR delete AS 
BEGIN

if exists (select 1 from config (nolock) where flag='TRIG_DEL_XFRL' and value_str='DISABLE')
  return

if exists (select 1 from deleted where status >= 'R') 
begin
  rollback tran
  exec adm_raiserror 77199, 'You Cannot Delete A Shipped Transfer!'
  return
end

DECLARE @d_xfer_no int, @d_line_no int, @d_from_loc varchar(10), @d_to_loc varchar(10),
@d_part_no varchar(30), @d_description varchar(255), @d_time_entered datetime,
@d_ordered decimal(20,8), @d_shipped decimal(20,8), @d_comment varchar(255), @d_status char(1),
@d_cost decimal(20,8), @d_com_flag char(1), @d_who_entered varchar(20),
@d_temp_cost decimal(20,8), @d_uom char(2), @d_conv_factor decimal(20,8),
@d_std_cost decimal(20,8), @d_from_bin varchar(12), @d_to_bin varchar(12),
@d_lot_ser varchar(25), @d_date_expires datetime, @d_lb_tracking char(1), @d_labor decimal(20,8),
@d_direct_dolrs decimal(20,8), @d_ovhd_dolrs decimal(20,8), @d_util_dolrs decimal(20,8),
@d_row_id int, @d_display_line int, @d_qty_rcvd decimal(20,8), @d_reference_code varchar(32),
@d_adj_code varchar(8), @d_amt_variance decimal(20,8)

declare @rc int, @mtd_qty decimal(20,8), @msg varchar(255)

DECLARE t700delxfer_cursor CURSOR LOCAL STATIC FOR
SELECT d.xfer_no, d.line_no, d.from_loc, d.to_loc, d.part_no, d.description, d.time_entered,
d.ordered, d.shipped, d.comment, d.status, d.cost, d.com_flag, d.who_entered, d.temp_cost,
d.uom, d.conv_factor, d.std_cost, d.from_bin, d.to_bin, d.lot_ser, d.date_expires,
d.lb_tracking, d.labor, d.direct_dolrs, d.ovhd_dolrs, d.util_dolrs, d.row_id, d.display_line,
d.qty_rcvd, d.reference_code, d.adj_code, d.amt_variance
from deleted d

OPEN t700delxfer_cursor

if @@cursor_rows = 0
begin
CLOSE t700delxfer_cursor
DEALLOCATE t700delxfer_cursor
return
end

FETCH NEXT FROM t700delxfer_cursor into
@d_xfer_no, @d_line_no, @d_from_loc, @d_to_loc, @d_part_no, @d_description, @d_time_entered,
@d_ordered, @d_shipped, @d_comment, @d_status, @d_cost, @d_com_flag, @d_who_entered,
@d_temp_cost, @d_uom, @d_conv_factor, @d_std_cost, @d_from_bin, @d_to_bin, @d_lot_ser,
@d_date_expires, @d_lb_tracking, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs,
@d_row_id, @d_display_line, @d_qty_rcvd, @d_reference_code, @d_adj_code, @d_amt_variance

While @@FETCH_STATUS = 0
begin
  if @d_status = 'N'
    update inv_xfer 
      set commit_ed=commit_ed - (@d_ordered * @d_conv_factor)
    where inv_xfer.part_no=@d_part_no and inv_xfer.location=@d_from_loc

  if (@d_status='N' or @d_status='P')
    update inv_xfer 
      set commit_to_loc=commit_to_loc - (@d_ordered * @d_conv_factor) 
    where inv_xfer.part_no=@d_part_no and inv_xfer.location=@d_to_loc

  if (@d_status='Q' or @d_status='P')
    update inv_xfer 
      set hold_xfr=(inv_xfer.hold_xfr - (@d_shipped * @d_conv_factor))
    where inv_xfer.part_no=@d_part_no and inv_xfer.location=@d_from_loc

  if @d_status='R'
    update inv_xfer 
      set transit=transit - (@d_shipped * @d_conv_factor)
    where inv_xfer.part_no=@d_part_no and inv_xfer.location=@d_to_loc

  if (@d_status='S' or @d_status='Q' or @d_status='P' or @d_status='R') 
  begin
    update inv_xfer 
    set xfer_mtd=(xfer_mtd + (@d_shipped * @d_conv_factor)),
      xfer_ytd=(xfer_ytd + (@d_shipped * @d_conv_factor))
    where inv_xfer.part_no=@d_part_no and inv_xfer.location=@d_from_loc

    -- mls 1/18/05 SCR 34050
    select @mtd_qty = (@d_shipped * @d_conv_factor)
    exec @rc = adm_inv_mtd_upd @d_part_no, @d_from_loc, 'X', @mtd_qty
    if @rc < 1
    begin
      select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
      rollback tran
      exec adm_raiserror 9910141 ,@msg
      return
    end
  end

  delete lot_bin_xfer 
  where lot_bin_xfer.tran_no=@d_xfer_no and  lot_bin_xfer.line_no=@d_line_no and
    lot_bin_xfer.part_no=@d_part_no


  
  declare @tdc_rtn int, @stat varchar(10), @qty decimal(20,8)
  SELECT @stat = 'XFERL_DEL'

  select @qty=(@d_shipped * @d_conv_factor)

  exec @tdc_rtn = tdc_xfer_list_change @d_xfer_no, @d_line_no, @d_part_no, @qty, @stat

  if (@tdc_rtn< 0 )
  begin
    exec adm_raiserror 77900, 'Invalid Inventory Update From TDC.'
  end
  


FETCH NEXT FROM t700delxfer_cursor into
@d_xfer_no, @d_line_no, @d_from_loc, @d_to_loc, @d_part_no, @d_description, @d_time_entered,
@d_ordered, @d_shipped, @d_comment, @d_status, @d_cost, @d_com_flag, @d_who_entered,
@d_temp_cost, @d_uom, @d_conv_factor, @d_std_cost, @d_from_bin, @d_to_bin, @d_lot_ser,
@d_date_expires, @d_lb_tracking, @d_labor, @d_direct_dolrs, @d_ovhd_dolrs, @d_util_dolrs,
@d_row_id, @d_display_line, @d_qty_rcvd, @d_reference_code, @d_adj_code, @d_amt_variance
end -- while

CLOSE t700delxfer_cursor
DEALLOCATE t700delxfer_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t602insxferl] ON [dbo].[xfer_list] FOR insert AS 
BEGIN
if exists (select 1 from config (nolock) where flag='TRIG_INS_XFRL' and value_str='DISABLE') return

DECLARE @i_xfer_no int, @i_line_no int, @i_from_loc varchar(10), @i_to_loc varchar(10),
@i_part_no varchar(30), @i_description varchar(255), @i_time_entered datetime,
@i_ordered decimal(20,8), @i_shipped decimal(20,8), @i_comment varchar(255), @i_status char(1),
@i_cost decimal(20,8), @i_com_flag char(1), @i_who_entered varchar(20),
@i_temp_cost decimal(20,8), @i_uom char(2), @i_conv_factor decimal(20,8),
@i_std_cost decimal(20,8), @i_from_bin varchar(12), @i_to_bin varchar(12),
@i_lot_ser varchar(25), @i_date_expires datetime, @i_lb_tracking char(1), @i_labor decimal(20,8),
@i_direct_dolrs decimal(20,8), @i_ovhd_dolrs decimal(20,8), @i_util_dolrs decimal(20,8),
@i_row_id int, @i_display_line int, @i_qty_rcvd decimal(8,0), @i_reference_code varchar(32),
@i_adj_code varchar(8),
@rc int, @mtd_qty decimal(20,8)

declare @in_commit_ed decimal(20,8), @in_commit_to_loc decimal(20,8), @in_hold_xfr decimal(20,8),
  @in_from_mtd decimal(20,8)
declare @a_tran_qty decimal(20,8), @a_tran_data varchar(255), @retval int, @a_tran_id int, @COGS int, @in_stock decimal(20,8),
@unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8), @labor decimal(20,8),
@a_unitcost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_utility decimal(20,8), @a_labor decimal(20,8),
@msg varchar(255)

DECLARE t700insxfer_cursor CURSOR LOCAL STATIC FOR
SELECT i.xfer_no, i.line_no, i.from_loc, i.to_loc, i.part_no, i.description, i.time_entered,
i.ordered, i.shipped, i.comment, i.status, i.cost, i.com_flag, i.who_entered, i.temp_cost,
i.uom, i.conv_factor, i.std_cost, i.from_bin, i.to_bin, i.lot_ser, i.date_expires,
i.lb_tracking, i.labor, i.direct_dolrs, i.ovhd_dolrs, i.util_dolrs, i.row_id, i.display_line,
i.qty_rcvd, i.reference_code, i.adj_code
from inserted i

OPEN t700insxfer_cursor

if @@cursor_rows = 0
begin
CLOSE t700insxfer_cursor
DEALLOCATE t700insxfer_cursor
return
end

FETCH NEXT FROM t700insxfer_cursor into
@i_xfer_no, @i_line_no, @i_from_loc, @i_to_loc, @i_part_no, @i_description, @i_time_entered,
@i_ordered, @i_shipped, @i_comment, @i_status, @i_cost, @i_com_flag, @i_who_entered,
@i_temp_cost, @i_uom, @i_conv_factor, @i_std_cost, @i_from_bin, @i_to_bin, @i_lot_ser,
@i_date_expires, @i_lb_tracking, @i_labor, @i_direct_dolrs, @i_ovhd_dolrs, @i_util_dolrs,
@i_row_id, @i_display_line, @i_qty_rcvd, @i_reference_code, @i_adj_code

While @@FETCH_STATUS = 0
begin
  if @i_status >= 'R'
  BEGIN
    rollback tran
    exec adm_raiserror 87105, 'You can not insert a transfer line in a shipped or received status.'
    RETURN
  END

  if not exists (select 1 from inv_xfer (nolock) where @i_part_no=part_no and @i_to_loc=location)
  begin
    rollback tran
    exec adm_raiserror 87101 ,'Invalid Part Number - Check Location/Part!'
    return
  end

  if not exists (select 1 from inv_xfer (nolock) where @i_part_no=part_no and @i_from_loc=location)
  begin
    rollback tran
    exec adm_raiserror 87103 ,'Invalid Part Number - Check Location/Part!'
    return
  end

  IF Exists( select 1 from inv_master (nolock) where @i_part_no= part_no and status in ('C','V'))
  BEGIN
    rollback tran
    exec adm_raiserror 87104 ,'You can not transfer Custom Kit or Non-Quantity Bearing Items.'
    RETURN
  END

  select @in_commit_ed = 	case when @i_status in ('N','P','Q') then ((@i_ordered - @i_shipped) * @i_conv_factor) else 0 end,
    @in_commit_to_loc = 	case when @i_status in ('N','P','Q') then (@i_ordered * @i_conv_factor) else 0 end,
    @in_hold_xfr = 		case when @i_status in ('Q','P') then (@i_shipped * @i_conv_factor) else 0 end,
    @in_from_mtd = 		case when @i_status in ('P','Q','R','S') then @i_shipped else 0 end

  select @a_tran_qty = - @in_from_mtd

  if @a_tran_qty != 0 
  begin
    select @a_unitcost = 0, @a_direct = 0, @a_overhead = 0, @a_utility = 0, @a_labor = 0
         
    select @a_tran_data =
      convert(varchar(30),0) + replicate(' ',30 - datalength(convert(varchar(30),0)))

    exec @retval = adm_inv_tran 
      'X', @i_xfer_no, 0, @i_line_no, @i_part_no, @i_from_loc, @a_tran_qty, NULL, @i_uom, 
      @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT, 
      @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,
      @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT
    if @retval <> 1
    begin
      rollback tran
      select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
      exec adm_raiserror 83202 ,@msg
      RETURN
    end
  end

  if @i_status in ('N','P','Q')
  begin
    update inv_xfer 
    set commit_ed=commit_ed + @in_commit_ed,
      hold_xfr=hold_xfr + @in_hold_xfr,
      xfer_mtd=xfer_mtd - @in_from_mtd,
      xfer_ytd=xfer_ytd - @in_from_mtd
    from inv_xfer 
    where part_no=@i_part_no and location=@i_from_loc

    -- mls 1/18/05 SCR 34050
    select @mtd_qty = - @in_from_mtd
    exec @rc = adm_inv_mtd_upd @i_part_no, @i_from_loc, 'X', @mtd_qty
    if @rc < 1
    begin
      select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
      rollback tran
      exec adm_raiserror 9910141,@msg
      return
    end
  end

  if @i_status in ('N','P')
  begin
    update inv_xfer set commit_to_loc=commit_to_loc + @in_commit_to_loc
    from inv_xfer 
    where part_no=@i_part_no and location=@i_to_loc
  end


  

  declare @tdc_rtn int, @stat varchar(10), @qty decimal(20,8)

  select @qty=(@i_shipped * @i_conv_factor),
    @stat = 'XFERL_INS'

  exec @tdc_rtn = tdc_xfer_list_change @i_xfer_no, @i_line_no, @i_part_no, @qty, @stat

  if (@tdc_rtn< 0 )
    exec adm_raiserror 87900 ,'Invalid Inventory Update From TDC.'

  

FETCH NEXT FROM t700insxfer_cursor into
@i_xfer_no, @i_line_no, @i_from_loc, @i_to_loc, @i_part_no, @i_description, @i_time_entered,
@i_ordered, @i_shipped, @i_comment, @i_status, @i_cost, @i_com_flag, @i_who_entered,
@i_temp_cost, @i_uom, @i_conv_factor, @i_std_cost, @i_from_bin, @i_to_bin, @i_lot_ser,
@i_date_expires, @i_lb_tracking, @i_labor, @i_direct_dolrs, @i_ovhd_dolrs, @i_util_dolrs,
@i_row_id, @i_display_line, @i_qty_rcvd, @i_reference_code, @i_adj_code
end -- while

CLOSE t700insxfer_cursor
DEALLOCATE t700insxfer_cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t700updxferl] ON [dbo].[xfer_list]   FOR UPDATE  AS 
BEGIN
  if (select count(1) from inserted) = 0 return
  

  if update(cost) AND NOT update(ordered) AND NOT update(shipped) AND NOT update(conv_factor)
    AND NOT update(to_loc) AND NOT update(from_loc) AND NOT update(part_no) 
    AND NOT update(status)
    AND NOT update(qty_rcvd)										-- mls 2/11/03 SCR 30654 
  begin
    return
  end

  if not (update(status) or update(part_no) or update(to_loc) or update(from_loc) or update(xfer_no) -- mls 11/17/00 SCR 24912 start
  or update(line_no) or update(ordered) or update(shipped) or update (conv_factor) or update (amt_variance)
  or update(qty_rcvd))											-- mls 2/11/03 SCR 30654
  begin 
    return
  end												-- mls 11/17/00 SCR 24912 end

  if exists (select 1 from config (nolock) where flag='TRIG_UPD_XFRL' and value_str='DISABLE') return

declare
@i_xfer_no int  ,
@i_line_no int  ,
@i_from_loc varchar (10)  ,
@i_to_loc varchar (10)  ,
@i_part_no varchar (30)  ,
@i_description varchar (255)  ,
@i_time_entered datetime  ,
@i_ordered decimal(20, 8)  ,
@i_shipped decimal(20, 8)  ,
@i_comment varchar (255)  ,
@i_status char (1)  ,
@i_cost decimal(20, 8)  ,
@i_com_flag char (1)  ,
@i_who_entered varchar (20)  ,
@i_temp_cost decimal(20, 8)  ,
@i_uom char (2)  ,
@i_conv_factor decimal(20, 8)  ,
@i_std_cost decimal(20, 8)  ,
@i_from_bin varchar (12)  ,
@i_to_bin varchar (12)  ,
@i_lot_ser varchar (25)  ,
@i_date_expires datetime  ,
@i_lb_tracking char (1)  ,
@i_labor decimal(20, 8)  ,
@i_direct_dolrs decimal(20, 8)  ,
@i_ovhd_dolrs decimal(20, 8)  ,
@i_util_dolrs decimal(20, 8)  ,
@i_row_id int  ,
@i_display_line int  ,
@i_qty_rcvd decimal(20, 8)  ,								-- mls 2/11/03 SCR 30654
@i_reference_code varchar (32)  ,
@i_adj_code varchar (8),
@i_amt_variance decimal(20,8)

declare
@d_xfer_no int  ,
@d_line_no int  ,
@d_from_loc varchar (10)  ,
@d_to_loc varchar (10)  ,
@d_part_no varchar (30)  ,
@d_description varchar (255)  ,
@d_time_entered datetime  ,
@d_ordered decimal(20, 8)  ,
@d_shipped decimal(20, 8)  ,
@d_comment varchar (255)  ,
@d_status char (1)  ,
@d_cost decimal(20, 8)  ,
@d_com_flag char (1)  ,
@d_who_entered varchar (20)  ,
@d_temp_cost decimal(20, 8)  ,
@d_uom char (2)  ,
@d_conv_factor decimal(20, 8)  ,
@d_std_cost decimal(20, 8)  ,
@d_from_bin varchar (12)  ,
@d_to_bin varchar (12)  ,
@d_lot_ser varchar (25)  ,
@d_date_expires datetime  ,
@d_lb_tracking char (1)  ,
@d_labor decimal(20, 8)  ,
@d_direct_dolrs decimal(20, 8)  ,
@d_ovhd_dolrs decimal(20, 8)  ,
@d_util_dolrs decimal(20, 8)  ,
@d_row_id int  ,
@d_display_line int  ,
@d_qty_rcvd decimal(20, 8)  ,								-- mls 2/11/03 SCR 30654
@d_reference_code varchar (32)  ,
@d_adj_code varchar (8),
@d_amt_variance decimal(20,8)

  declare @retval int
  declare @qty decimal(20,8),@tran_date datetime,
    @xfers_date_recvd datetime, @xfers_date_shipped datetime, @xfers_to_org_id varchar(30),
    @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8),
    @labor decimal(20,8), @utility decimal(20,8),
    @operunitcost decimal(20,8), @operdirect decimal(20,8), @operoverhead decimal(20,8),
    @opercost decimal(20,8), @operutility decimal(20,8)
  DECLARE @d_unitcost decimal(20,8), @d_direct decimal(20,8), @d_overhead decimal(20,8)
  DECLARE @d_utility decimal(20,8), @d_operunitcost decimal(20,8), @d_operdirect decimal(20,8)
  DECLARE @d_operoverhead decimal(20,8), @d_operutility decimal(20,8)
  DECLARE @COGS int -- Cost Of Goods Sold flag.  
  DECLARE @in_stock decimal(20,8) -- current stock of the part in question
  DECLARE @dummycost decimal (20,8), @temp_qty decimal (20,8)
  DECLARE @ar_cgs_code varchar(32), @ar_cgs_direct_code varchar(32), @ar_cgs_ovhd_code varchar(32),
    @ar_cgs_util_code varchar(32)
  DECLARE @posting_code varchar(10), @glaccount varchar(32), @natcode varchar(8)
  DECLARE @inv_acct varchar(32),@direct_acct varchar(32),@ovhd_acct varchar(32),@util_acct varchar(32)
  DECLARE @xfer varchar(32)
  DECLARE @cost decimal(20,8), @to_loc varchar(10)
  DECLARE @iloop int,@company_id int, @direction int, @return int
  DECLARE @from_unitcost decimal(20,8), @from_direct decimal(20,8), @from_overhead decimal(20,8), @from_utility decimal(20,8),
    @cost_var_code varchar(32), @cost_var_dir varchar(32), @cost_var_ovhd varchar(32), @cost_var_util varchar(32),
    @variance decimal(20,8) 									
  DECLARE @typ char(1), @o_avg_cost decimal(20,8), 						-- mls 5/4/00 SCR 22565
    @o_direct_dolrs decimal(20,8), @o_ovhd_dolrs decimal(20,8),@o_util_dolrs decimal(20,8),	-- mls 5/4/00 SCR 22565
    @i_avg_cost decimal(20,8),
    @o_std_cost decimal(20,8), @o_std_direct_dolrs decimal(20,8), 
    @o_std_ovhd_dolrs decimal(20,8),@o_std_util_dolrs decimal(20,8)
  DECLARE @in_commit_ed decimal(20,8), @dl_commit_ed decimal(20,8), @in_commit_to_loc decimal(20,8),
    @dl_commit_to_loc decimal(20,8), @in_hold_xfr decimal(20,8), @dl_hold_xfr decimal(20,8),
    @in_transit decimal(20,8), @dl_transit decimal(20,8), @in_from_mtd decimal(20,8),
    @dl_from_mtd decimal(20,8), @in_to_mtd decimal(20,8), @dl_to_mtd decimal(20,8)
  DECLARE @row_id int, @t_posting_code varchar(10),
  @tempqty decimal(20,8), @line_descr varchar(50), @tot_cost decimal(20,8), @line_descr1 varchar(50),
  @pos_qty decimal(20,8), @pos_cost decimal(20,8),
  @glcost1 decimal(20,8), @glqty1 decimal(20,8), @glcost2 decimal(20,8), @glqty2 decimal(20,8)

declare @a_tran_id int, @a_tran_qty decimal(20,8), @a_tran_data varchar(255)
declare @a_unitcost decimal(20,8), @a_direct decimal(20,8), @a_overhead decimal(20,8), @a_utility decimal(20,8),
  @a_labor decimal(20,8)
declare @c_unitcost decimal(20,8), @c_direct decimal(20,8), @c_overhead decimal(20,8), @c_utility decimal(20,8),
  @c_labor decimal(20,8), @c_qty decimal(20,8)
declare @v_unitcost decimal(20,8), @v_direct decimal(20,8), @v_overhead decimal(20,8), @v_utility decimal(20,8),
  @v_labor decimal(20,8)
declare @va_unitcost decimal(20,8), @va_direct decimal(20,8), @va_overhead decimal(20,8), @va_utility decimal(20,8),
  @va_labor decimal(20,8)
declare @d_amt decimal(20,8), @i_amt decimal(20,8)
declare @msg varchar(255), @l_in_stock decimal(20,8), @temp_cost decimal(20,8)
declare @cogs_qty decimal(20,8),
@rc int, @mtd_qty decimal(20,8)
declare @gl_loc varchar(10)

DECLARE @var_qty decimal(20,8), @qty_rcvd decimal(20,8),@var_mat_acct varchar(32) ,@var_direct_acct varchar(32), 
 @var_overh_acct varchar(32),@var_utility_acct varchar(32),@glaccount1 varchar(32),@flag_var int, @flag_cost int,
 @amt_variance decimal(20,8), @varcost decimal(20,8), @varqty decimal(20,8),					-- mls 2/11/03 SCR 30654
 @inv_lot_bin int

select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)
create table #lots (part_no varchar(30), location varchar(10), qty decimal(20,8), uom_qty decimal(20,8), 
  conv_qty decimal(20,8),typ int)

DECLARE updxfrl CURSOR LOCAL FOR
SELECT i.xfer_no, i.line_no, i.from_loc, i.to_loc, i.part_no, i.description, i.time_entered, i.ordered, 
i.shipped, i.comment, i.status, i.cost, i.com_flag, i.who_entered, i.temp_cost, i.uom, i.conv_factor, 
i.std_cost, i.from_bin, i.to_bin, i.lot_ser, i.date_expires, i.lb_tracking, i.labor, i.direct_dolrs, 
i.ovhd_dolrs, i.util_dolrs, i.row_id, i.display_line, isnull(i.qty_rcvd,0), i.reference_code, i.adj_code ,i.amt_variance,
d.xfer_no, d.line_no, d.from_loc, d.to_loc, d.part_no, d.description, d.time_entered, d.ordered, 
d.shipped, d.comment, d.status, d.cost, d.com_flag, d.who_entered, d.temp_cost, d.uom, d.conv_factor, 
d.std_cost, d.from_bin, d.to_bin, d.lot_ser, d.date_expires, d.lb_tracking, d.labor, d.direct_dolrs, 
d.ovhd_dolrs, d.util_dolrs, d.row_id, d.display_line, isnull(d.qty_rcvd,0), d.reference_code, d.adj_code,d.amt_variance 
FROM inserted i, deleted d
where i.row_id = d.row_id

OPEN updxfrl
FETCH NEXT FROM updxfrl into
@i_xfer_no, @i_line_no, @i_from_loc, @i_to_loc, @i_part_no, @i_description, @i_time_entered, @i_ordered, 
@i_shipped, @i_comment, @i_status, @i_cost, @i_com_flag, @i_who_entered, @i_temp_cost, @i_uom, @i_conv_factor, 
@i_std_cost, @i_from_bin, @i_to_bin, @i_lot_ser, @i_date_expires, @i_lb_tracking, @i_labor, @i_direct_dolrs, 
@i_ovhd_dolrs, @i_util_dolrs, @i_row_id, @i_display_line, @i_qty_rcvd, @i_reference_code, @i_adj_code ,@i_amt_variance,
@d_xfer_no, @d_line_no, @d_from_loc, @d_to_loc, @d_part_no, @d_description, @d_time_entered, @d_ordered, 
@d_shipped, @d_comment, @d_status, @d_cost, @d_com_flag, @d_who_entered, @d_temp_cost, @d_uom, @d_conv_factor, 
@d_std_cost, @d_from_bin, @d_to_bin, @d_lot_ser, @d_date_expires, @d_lb_tracking, @d_labor, @d_direct_dolrs, 
@d_ovhd_dolrs, @d_util_dolrs, @d_row_id, @d_display_line, @d_qty_rcvd, @d_reference_code, @d_adj_code,@d_amt_variance 

While @@FETCH_STATUS = 0
begin

  select @flag_var = 0
  select @amt_variance = @i_amt_variance * @i_conv_factor						-- mls 2/11/03 SCR 30654

  --Make sure they are only updating the To Bin of the Receipt
  if @d_status >= 'R' and
    (@i_ordered != @d_ordered or @i_shipped != @d_shipped or @i_conv_factor != @d_conv_factor
    or @i_to_loc != @d_to_loc or @i_from_loc != @d_from_loc or @i_part_no != @d_part_no)
  begin 
    rollback tran
    exec adm_raiserror 97104 ,'Only Bin Update Allowed on a Shipped Xfer!'
    return
  end

  if @i_xfer_no != @d_xfer_no or @i_line_no != @d_line_no
  begin
    rollback tran
    exec adm_raiserror 97101, 'You cannot change transfer number or transfer line number'
    return
  end

  if @i_shipped < 0
  begin
    rollback tran
    exec adm_raiserror 97105 ,'Negative Transfer NOT Allowed!'
    return
  end	
	
  if @d_status between 'S' and 'U'
  begin
    rollback tran
    exec adm_raiserror 97106 ,'Update of Received Transfer NOT Allowed!'
    return
  end	

  if @i_status <= 'N' and @i_shipped > 0
  begin
    rollback tran
    exec adm_raiserror 97107 ,'Cannot Enter Shipped Qty on a New Status!'
    return
  end	
 
  if @i_status in ('R','S')
  begin
    select @xfers_date_recvd =  date_recvd,
      @xfers_date_shipped = date_shipped,
      @xfers_to_org_id = isnull(to_organization_id,'')
    from xfers_all
    where xfer_no = @i_xfer_no

    if @@ROWCOUNT = 0
    begin
      rollback tran
      exec adm_raiserror 97100 ,'Cannot Find Header Record on Xfers Table!'
      return
    end	
  end

-- mls 11/1/04 SCR 33596
  declare @m_lb_tracking char(1), @lb_sum decimal(20,8), @part_cnt int,
    @lb_part varchar(30), @lb_loc varchar(10), @uom_sum decimal(20,8),
    @i_qty decimal(20,8)
  if @i_status = 'R'
  begin
    select @m_lb_tracking = isnull((select lb_tracking from inv_master (nolock) where part_no = @i_part_no),NULL)

    if @m_lb_tracking is null
    begin
      select @msg = 'Part ([' + @i_part_no + ']) does not exist in inventory.'
      rollback tran
      exec adm_raiserror 832111, @msg
      RETURN
    end

    if isnull(@m_lb_tracking,'N') != @i_lb_tracking
    begin
      select @msg = 'Lot bin tracking flag mismatch with inventory for part [' + @i_part_no + '].'
      rollback tran
      exec adm_raiserror 832112, @msg
      RETURN
    end

    delete from #lots
    if @i_lb_tracking = 'Y'
      insert #lots 
      values (@i_part_no, @i_from_loc, (@i_shipped ) * @i_conv_factor,
        (@i_shipped ),         (@i_shipped ), -1)
 

    insert #lots
    select part_no, location,
      sum(qty * direction), sum (uom_qty * direction), sum(qty / conv_factor * direction), -3
    from lot_bin_xfer
    where tran_no = @i_xfer_no and tran_ext = 0 and line_no = @i_line_no
    group by part_no, location

    insert #lots
    select part_no, location, sum(qty), sum(uom_qty), sum(conv_qty), 0
    from #lots
    group by part_no, location

    select @lb_sum = isnull(sum(qty),0),
      @uom_sum = isnull(sum(uom_qty),0),
      @part_cnt = count(distinct (part_no + '!@#' + location)) ,
      @lb_part = isnull(min(part_no),''),
      @lb_loc = isnull(min(location),'')
    from #lots
    where typ = -3

    if @inv_lot_bin = 0 and @part_cnt > 0
    begin
      select @msg = 'You cannot have lot bin records on an transfer when you are not lb tracking.'
      rollback tran
      exec adm_raiserror 832114,@msg
      RETURN
    end

    if @m_lb_tracking = 'Y' and @inv_lot_bin != 0	-- mls 9/25/06 SCR 36969
    begin
      if @part_cnt = 0 and (@i_shipped) <> 0
      begin
        select @msg = 'No lot bin records found on lot_bin_ship for this item ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113 ,@msg
        RETURN
      end

      if @part_cnt > 1
      begin
        select @msg = 'More than one parts lot bin records found on lot_bin_ship for this part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end

      select @i_qty = -(@i_shipped )

      if @uom_sum != @i_qty
      begin
        select @msg = 'Item uom qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@uom_sum) + 
          '] for part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end
      select @i_qty = @i_qty * @i_conv_factor
      if @lb_sum != @i_qty
      begin
        select @msg = 'Item qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) + 
          '] for part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113 ,@msg
        RETURN
      end

      if @part_cnt > 0
      begin
        if @lb_part != @i_part_no or @lb_loc != @i_from_loc
        begin
          select @msg = 'Part/Location on lot_bin_ship is not the same as on ord_list table.'
          rollback tran
          exec adm_raiserror 832115,@msg
          RETURN
        end
      end
    end
    else
    begin
      if @part_cnt > 0
      begin
        select @msg = 'Lot bin records found on lot_bin_ship for this not lot/bin tracked part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832114, @msg
        RETURN
      end
    end
  end  -- @i_status = 'R'

  if @i_status = 'S' and (@i_shipped - @i_qty_rcvd) != @i_amt_variance						-- mls 2/11/03 SCR 30654 start
  begin
      rollback tran
      exec adm_raiserror 97101 ,'Amount variance does not equal difference in shipped and received amounts on received transfer'
      return
  end														-- mls 2/11/03 SCR 30654 end

  if @i_status = 'S'
  begin
    select @m_lb_tracking = isnull((select lb_tracking from inv_master (nolock) where part_no = @i_part_no),NULL)

    if @m_lb_tracking is null
    begin
      select @msg = 'Part ([' + @i_part_no + ']) does not exist in inventory.'
      rollback tran
      exec adm_raiserror 832111, @msg
      RETURN
    end

    if isnull(@m_lb_tracking,'N') != @i_lb_tracking
    begin
      select @msg = 'Lot bin tracking flag mismatch with inventory for part [' + @i_part_no + '].'
      rollback tran
      exec adm_raiserror 832112, @msg
      RETURN
    end

    delete from #lots
    if @i_lb_tracking = 'Y'
      insert #lots 
      values (@i_part_no, @i_from_loc, (@i_qty_rcvd ) * @i_conv_factor,
        (@i_qty_rcvd ),         (@i_qty_rcvd ), -1)

    insert #lots
    select part_no, @i_to_loc,
      sum(convert(decimal(20,8),qty_received * conv_factor) * direction),
      sum (qty_received * direction), sum(convert(decimal(20,8),qty_received * conv_factor) * direction), -3
    from lot_bin_xfer
    where tran_no = @i_xfer_no and tran_ext = 0 and line_no = @i_line_no
    group by part_no

    insert #lots
    select part_no, location, sum(qty), sum(uom_qty), sum(conv_qty), 0
    from #lots
    group by part_no, location

    select @lb_sum = isnull(sum(qty),0),
      @uom_sum = isnull(sum(uom_qty),0),
      @part_cnt = count(distinct (part_no + '!@#' + location)) ,
      @lb_part = isnull(min(part_no),''),
      @lb_loc = isnull(min(location),'')
    from #lots
    where typ = -3

    if @inv_lot_bin = 0 and @part_cnt > 0
    begin
      select @msg = 'You cannot have lot bin records on an transfer when you are not lb tracking.'
      rollback tran
      exec adm_raiserror 832114 ,@msg
      RETURN
    end

    if @m_lb_tracking = 'Y' and @inv_lot_bin != 0	-- mls 9/25/06 SCR 36969
    begin
      if @part_cnt = 0 and (@i_qty_rcvd) <> 0
      begin
        select @msg = 'No lot bin records found on lot_bin_ship for this item ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end

      if @part_cnt > 1
      begin
        select @msg = 'More than one parts lot bin records found on lot_bin_ship for this part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113 ,@msg
        RETURN
      end

      select @i_qty = -(@i_qty_rcvd )

      if @uom_sum != @i_qty
      begin
        select @msg = 'Item uom qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@uom_sum) + 
          '] for part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113,@msg
        RETURN
      end
      select @i_qty = @i_qty * @i_conv_factor
      if @lb_sum != @i_qty
      begin
        select @msg = 'Item qty of [' + convert(varchar,@i_qty) + '] does not equal the lot and bin qty of [' + convert(varchar,@lb_sum) + 
          '] for part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832113, @msg
        RETURN
      end

      if @part_cnt > 0
      begin
        if @lb_part != @i_part_no or @lb_loc != @i_to_loc
        begin
          select @msg = 'Part/Location on lot_bin_ship is not the same as on ord_list table.'
          rollback tran
          exec adm_raiserror 832115, @msg
          RETURN
        end
      end
    end
    else
    begin
      if @part_cnt > 0
      begin
        select @msg = 'Lot bin records found on lot_bin_ship for this not lot/bin tracked part ([' + @i_part_no + ']).'
        rollback tran
        exec adm_raiserror 832114, @msg
        RETURN
      end
    end
  end  -- @i_status = 'S'

  if @i_status = 'R'
    select @a_unitcost = 0, @a_direct = 0, @a_overhead = 0, @a_utility = 0, @a_labor = 0
  if @i_status = 'S'
    select @a_unitcost = @i_cost , @a_direct = @i_direct_dolrs ,
      @a_overhead = @i_ovhd_dolrs , @a_utility = @i_util_dolrs ,
      @a_labor = @i_labor 


  if (select count(1) from inv_xfer (nolock)							-- mls 11/17/00 SCR 24912 start
    where part_no = @i_part_no and location in (@i_to_loc,@i_from_loc)) !=
    case when @i_to_loc = @i_from_loc then 1 else 2 end
  begin
    rollback tran
    exec adm_raiserror 97101 ,'Invalid Part Number - Check Location/Part!'
    return
  end												-- mls 11/17/00 SCR 24912 end

  
  select @a_tran_id = 0  , @a_tran_data = ''
  select @c_unitcost = 0, @c_direct = 0, @c_overhead = 0, @c_utility = 0, @c_qty = 0,
    @v_unitcost = 0, @v_direct = 0, @v_overhead = 0, @v_utility = 0

  
  if @d_status < 'T'  and (@i_status < 'T' or @i_status = 'V')					
  BEGIN

    if @i_status in ('N','P','Q','R','S') or @d_status in ('N','P','Q','R','S')
    begin



      select @in_commit_ed = 	case when @i_status in ('N','P','Q') then ((@i_ordered - @i_shipped) * @i_conv_factor) else 0 end,	-- mls 8/24/04 SCR 33413
        @dl_commit_ed = 	case when @d_status in ('N','P','Q') then ((@d_ordered - @d_shipped) * @d_conv_factor) else 0 end,	-- mls 8/24/04 SCR 33413
        @in_commit_to_loc = 	case when @i_status in ('N','P','Q') then (@i_ordered * @i_conv_factor) else 0 end,			-- mls 8/24/04 SCR 33413
	@dl_commit_to_loc = 	case when @d_status in ('N','P','Q') then ( @d_ordered * @d_conv_factor ) else 0 end,			-- mls 8/24/04 SCR 33413
	@in_hold_xfr = 		case when @i_status in ('Q','P') then (@i_shipped * @i_conv_factor) else 0 end,
	@dl_hold_xfr = 		case when @d_status in ('Q','P')then (@d_shipped * @d_conv_factor) else 0 end,
	@in_transit = 		case when @i_status = 'R'  then (@i_shipped * @i_conv_factor) else 0 end,
	@dl_transit = 		case when @d_status = 'R'  then (@d_shipped * @d_conv_factor) else 0 end,
	@in_from_mtd = 		case when @i_status in ('P','Q','R','S') then @i_shipped else 0 end,
	@dl_from_mtd = 		case when @d_status in ('P','Q','R','S') then @d_shipped else 0 end,
	@in_to_mtd = 		case when @i_status = 'S' then @i_qty_rcvd else 0 end,
	@dl_to_mtd = 		case when @d_status = 'S' then @d_qty_rcvd else 0 end

      select @d_amt = 0, @i_amt = 0, @a_tran_qty = 0
      if (@i_part_no != @d_part_no or @i_from_loc != @d_from_loc
        or @in_from_mtd != @dl_from_mtd or (@i_status = 'R' and @d_status < 'R'))
      begin
        if (@i_status = @d_status) and @i_status >= 'R'
          and NOT (@i_part_no = @d_part_no and @i_from_loc = @d_from_loc)
        begin
          rollback tran
          exec adm_raiserror 94136,'You cannot change the part number or location on a transfer that has been shipped'
          return
        end

        select @d_amt = @dl_from_mtd * @d_conv_factor, @i_amt = @in_from_mtd * @i_conv_factor,
          @a_tran_qty = 0

        if @i_part_no = @d_part_no and @i_from_loc = @d_from_loc
          select @a_tran_qty = case when @i_status = 'R' 
            then - @in_from_mtd else (@d_amt - @i_amt) / @i_conv_factor end +
            case when @d_status = 'R' then @dl_from_mtd else 0 end
        else
          select @a_tran_qty = - @in_from_mtd

        if @a_tran_qty != 0 or (@i_status = 'R' and (@d_amt != @i_amt))
        begin
          select @a_unitcost = @a_unitcost * @a_tran_qty, @a_direct = @a_direct * @a_tran_qty,
            @a_overhead = @a_overhead * @a_tran_qty, @a_utility = @a_utility * @a_tran_qty,
            @a_labor = @a_labor * @a_tran_qty
         
          select @a_tran_data =
              convert(varchar(30),@dl_hold_xfr) + replicate(' ',30 - datalength(convert(varchar(30),@dl_hold_xfr)))

          exec @retval = adm_inv_tran 
            'X', @i_xfer_no, 0, @i_line_no, @i_part_no, @i_from_loc, @a_tran_qty, @xfers_date_shipped, @i_uom, 
            @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT, 
            @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,
            @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
          if @retval <> 1
          begin
            rollback tran
            select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
            exec adm_raiserror 83202, @msg
            RETURN
          end
        end
      end
      if (@i_part_no != @d_part_no or @i_to_loc != @d_to_loc
        or @in_to_mtd != @dl_to_mtd or (@i_status = 'S' and @d_status < 'S'))
      begin
        select @a_tran_qty = @in_to_mtd
        select @in_to_mtd = @in_to_mtd * @i_conv_factor, @dl_to_mtd = @dl_to_mtd * @i_conv_factor

        if @a_tran_qty >= 0										-- mls 2/4/04 SCR 32407
        begin
          select @a_unitcost = @a_unitcost * @a_tran_qty, @a_direct = @a_direct * @a_tran_qty,
            @a_overhead = @a_overhead * @a_tran_qty, @a_utility = @a_utility * @a_tran_qty,
            @a_labor = @a_labor * @a_tran_qty

          select @va_unitcost = @a_unitcost, @va_direct = @a_direct,
            @va_overhead = @a_overhead , @va_utility = @a_utility,
            @va_labor = @a_labor 

          select @a_tran_data =
              convert(varchar(30),0) + replicate(' ',30 - datalength(convert(varchar(30),0)))
          
          exec @retval = adm_inv_tran 
            'X', @i_xfer_no, 0, @i_line_no, @i_part_no, @i_to_loc, @a_tran_qty, @xfers_date_recvd, @i_uom, 
            @i_conv_factor, @i_status, @a_tran_data OUT, DEFAULT, 
            @a_tran_id OUT, @a_unitcost OUT, @a_direct OUT, @a_overhead OUT, @a_utility OUT, @a_labor OUT,
            @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, @labor OUT, @in_stock OUT, @typ OUT
          if @retval <> 1
          begin
            rollback tran
            select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
            exec adm_raiserror 83202, @msg
            RETURN
          end

          select @cogs_qty = convert(decimal(20,8),substring(@a_tran_data,1,30))

          if @COGS != 0
            select @c_unitcost = @a_unitcost - @unitcost,
              @c_direct = @a_direct - @direct,
              @c_overhead =  @a_overhead - @overhead,
              @c_utility =  @a_utility - @utility, @c_qty = @cogs_qty
          else
            select @v_unitcost = @a_unitcost - @unitcost,
              @v_direct = @a_direct - @direct,
              @v_overhead = @a_overhead - @overhead,
              @v_utility = @a_utility - @utility

          if @amt_variance != 0
          begin
            select @va_unitcost = case when @a_unitcost != @va_unitcost then (@i_cost * @i_shipped) - @a_unitcost  else @i_cost * @i_amt_variance end,
              @va_direct = case when @a_direct != @va_direct then (@i_direct_dolrs * @i_shipped) - @a_direct  else @i_direct_dolrs * @i_amt_variance end,
              @va_overhead = case when @a_overhead != @va_overhead then (@i_ovhd_dolrs * @i_shipped) - @a_overhead  else @i_ovhd_dolrs * @i_amt_variance end,
              @va_utility = case when @a_utility != @va_utility then (@i_util_dolrs * @i_shipped) - @a_utility  else @i_util_dolrs * @i_amt_variance end
          end
        end
      end
      select @in_from_mtd = @in_from_mtd * @i_conv_factor, @dl_from_mtd = @dl_from_mtd * @d_conv_factor

      if @i_from_loc = @d_from_loc and @i_part_no = @d_part_no
      begin
        select @in_commit_ed = @in_commit_ed - @dl_commit_ed, @dl_commit_ed = 0,
	  @in_hold_xfr = @in_hold_xfr - @dl_hold_xfr, @dl_hold_xfr = 0,
	  @in_from_mtd = @in_from_mtd - @dl_from_mtd, @dl_from_mtd = 0
      end
      if @i_to_loc = @d_to_loc and @i_part_no = @d_part_no
      begin
	select
	  @in_commit_to_loc = @in_commit_to_loc - @dl_commit_to_loc, @dl_commit_to_loc = 0,
	  @in_transit = @in_transit - @dl_transit, @dl_transit = 0,
	  @in_to_mtd = @in_to_mtd - @dl_to_mtd, @dl_to_mtd = 0
      end

      if @in_commit_ed != 0 or @in_hold_xfr != 0 or @in_from_mtd != 0 
      begin
        update inv_xfer set 
          commit_ed=commit_ed + @in_commit_ed,
          hold_xfr = hold_xfr + @in_hold_xfr,
 	  xfer_mtd = xfer_mtd - @in_from_mtd,
	  xfer_ytd = xfer_ytd - @in_from_mtd
	where part_no = @i_part_no and location = @i_from_loc

        -- mls 1/18/05 SCR 34050
        select @mtd_qty = - @in_from_mtd
        exec @rc = adm_inv_mtd_upd @i_part_no, @i_from_loc, 'X', @mtd_qty
        if @rc < 1
        begin
          select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
          rollback tran
          exec adm_raiserror 9910141, @msg
          return
        end
      end
      if @dl_commit_ed != 0 or @dl_hold_xfr != 0 or @dl_from_mtd != 0 
      begin
        update inv_xfer set 
          commit_ed=commit_ed - @dl_commit_ed,
          hold_xfr = hold_xfr - @dl_hold_xfr,
 	  xfer_mtd = xfer_mtd + @dl_from_mtd,
	  xfer_ytd = xfer_ytd + @dl_from_mtd
	where part_no = @d_part_no and location = @d_from_loc

        -- mls 1/18/05 SCR 34050
        exec @rc = adm_inv_mtd_upd @d_part_no, @d_from_loc, 'X', @dl_from_mtd
        if @rc < 1
        begin
          select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
          rollback tran
          exec adm_raiserror 9910141, @msg
          return
        end
      end

      if @in_commit_to_loc != 0 or @in_transit != 0 or @in_to_mtd != 0
      begin
        update inv_xfer set 
          commit_to_loc=commit_to_loc + @in_commit_to_loc,
	  transit = transit + @in_transit,
 	  xfer_mtd = xfer_mtd + @in_to_mtd,
	  xfer_ytd = xfer_ytd + @in_to_mtd
	where part_no = @i_part_no and location = @i_to_loc

        -- mls 1/18/05 SCR 34050
        exec @rc = adm_inv_mtd_upd @i_part_no, @i_to_loc, 'X', @in_to_mtd
        if @rc < 1
        begin
          select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
          rollback tran
          exec adm_raiserror 9910141, @msg
          return
        end
      end

      if @dl_commit_to_loc != 0 or @dl_transit != 0 or @dl_to_mtd != 0
      begin
        update inv_xfer set 
          commit_to_loc=commit_to_loc - @dl_commit_to_loc,
	  transit = transit - @dl_transit,
 	  xfer_mtd = xfer_mtd - @dl_to_mtd,
	  xfer_ytd = xfer_ytd - @dl_to_mtd
	  where part_no = @d_part_no and location = @d_to_loc

        -- mls 1/18/05 SCR 34050
        select @mtd_qty = - @dl_to_mtd
        exec @rc = adm_inv_mtd_upd @d_part_no, @d_to_loc, 'X', @mtd_qty
        if @rc < 1
        begin
          select @msg = 'Error ([' + convert(varchar,@rc) + ']) returned from adm_inv_mtd_upd'
          rollback tran
          exec adm_raiserror 9910141 ,@msg
          return
        end
      end
    end											-- mls 11/17/00 SCR 24912 end

    if @i_status in ('V','N')								-- mls 11/17/00 SCR 24912
    begin
      delete lot_bin_xfer
      where tran_no= @i_xfer_no and line_no= @i_line_no
    end											-- mls 11/17/00 SCR 24912

  END -- dl_status < 'T'  and (in_status < 'T' or = 'V')					

  --Accounting Feeds
  --Process GL Feed for From Loc
  if @a_tran_qty != 0 and @a_tran_id != 0 and @i_status = 'R'				-- mls 4/12/00 SCR 22719  
  BEGIN
    select @qty = @a_tran_qty * @i_conv_factor
    if @company_id is NULL
    begin
      SELECT @company_id = company_id, @natcode = home_currency FROM glco (nolock)			
    end 
    --Get Location and Posting Code

    -- Get Accounts
    SELECT @direct_acct   = inv_direct_acct_code,
      @ovhd_acct     = inv_ovhd_acct_code,
      @util_acct     = inv_util_acct_code,
      @inv_acct      = inv_acct_code,
      @xfer          = transfer_acct_code,	      
      @var_mat_acct = var_mat_acct ,
      @var_direct_acct = var_direct_acct , 
      @var_overh_acct = var_overh_acct,
      @var_utility_acct = var_utility_acct ,
      @posting_code  = a.acct_code
    FROM in_account a (nolock)
    JOIN inv_list l (nolock) on l.acct_code = a.acct_code 
    where l.part_no = @i_part_no and l.location = @i_from_loc

    if @i_to_loc != @i_from_loc
    begin
      SELECT @t_posting_code = acct_code						-- mls 3/29/00 SCR 21208 start
      FROM inv_list (nolock)
      WHERE part_no = @i_part_no AND location = @i_to_loc							

      if @t_posting_code != @posting_code
      begin
        SELECT @xfer = transfer_acct_code								
        FROM in_account(nolock)
        WHERE acct_code = @t_posting_code						-- mls 3/29/00 SCR 21208 end
      end
    end

    select @tot_cost = 0, @pos_qty = @qty 						-- mls 4/16/02 SCR 28686 
    --Inventory Accounts   
    SELECT @iloop = 1
 
    WHILE @iloop <= 4
    BEGIN 
      Select @pos_cost = 
        isnull(CASE @iloop
        WHEN 1 THEN @unitcost WHEN 2 THEN @direct WHEN 3 THEN @overhead WHEN 4 THEN @utility END,0),
       @glaccount = 
        CASE @iloop
        WHEN 1 THEN @inv_acct WHEN 2 THEN @direct_acct WHEN 3 THEN @ovhd_acct WHEN 4 THEN @util_acct END,
       @line_descr = 
        CASE @iloop
        WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' 
        WHEN 4 THEN 'inv_util_acct' END

      select @tot_cost = @tot_cost + (@pos_cost ), @temp_cost = @pos_cost / @pos_qty
       
      exec @retval = adm_gl_insert  @i_part_no,@i_from_loc,'X',@i_xfer_no,0, @i_line_no,		-- mls 1/24/01 SCR 20787
        @xfers_date_shipped,@pos_qty,@temp_cost,@glaccount,@natcode,DEFAULT,DEFAULT, @company_id,
        DEFAULT,DEFAULT, @a_tran_id, @line_descr,@pos_cost,@iloop

      IF @retval <= 0
      BEGIN
	select @msg = 'Error Inserting Inventory GL Costing Record ([' + convert(varchar,@retval) + '])!' 
        rollback tran
        exec adm_raiserror 97110, @msg
        return
      END

      SELECT @iloop = @iloop + 1
    END --While

    IF @tot_cost != 0
    BEGIN
      select @tot_cost = @tot_cost * -1
      select @pos_qty = @qty, @pos_cost = @tot_cost / @qty
      exec @retval = adm_gl_insert  @i_part_no,@i_from_loc,'X',@i_xfer_no,0, @i_line_no,		-- mls 1/24/01 SCR 20787
        @xfers_date_shipped,@pos_qty,@pos_cost,@xfer,@natcode,DEFAULT,DEFAULT, @company_id,
        DEFAULT,DEFAULT,@a_tran_id,'xfer_acct',@tot_cost,0
      IF @retval <= 0
      BEGIN
	select @msg = 'Error Inserting transfer account GL Costing Record ([' + convert(varchar,@retval) + '])!' 
        rollback tran
        exec adm_raiserror 97110, @msg
        return
      END
    END

  END -- status = R

  --Process GL Feed for To Loc
  if @i_status = 'S' AND @d_status < 'S'
  BEGIN
    select @qty = @a_tran_qty * @i_conv_factor
    select @l_in_stock = abs(@in_stock)

    if @company_id is NULL
    begin
      SELECT @company_id = company_id, @natcode = home_currency FROM glco (nolock)			
    end 

    -- Get Accounts -- SCR 21423 Add cost variance accounts to select
    SELECT @direct_acct   = inv_direct_acct_code,
      @ovhd_acct     = inv_ovhd_acct_code,
      @util_acct     = inv_util_acct_code,
      @inv_acct      = inv_acct_code,
      @xfer          = transfer_acct_code,
      @cost_var_code = cost_var_code, 
      @cost_var_dir  = cost_var_direct_code,
      @cost_var_ovhd = cost_var_ovhd_code,
      @cost_var_util = cost_var_util_code, 
      @var_mat_acct = var_mat_acct ,
      @var_direct_acct = var_direct_acct , 
      @var_overh_acct = var_overh_acct,
      @var_utility_acct = var_utility_acct , 	 	 
      @posting_code  = a.acct_code
    FROM in_account a (nolock)
    JOIN inv_list l (nolock) on l.acct_code = a.acct_code 
    where l.part_no = @i_part_no and l.location = @i_to_loc			-- mls 7/7/04 SCR 33131

    select @typ = inv_cost_method from inv_master (nolock) where part_no = @i_part_no
    --Inventory Accounts   
    SELECT @iloop = 0

    WHILE @iloop <= 4
    BEGIN 
      select
        @glcost1 = isnull(
          CASE @iloop
          WHEN 0 THEN -(@a_unitcost + @a_direct + @a_overhead + @a_utility)
          WHEN 1 THEN @unitcost WHEN 2 THEN @direct WHEN 3 THEN @overhead WHEN 4 THEN @utility end,0),
        @glqty1 = @qty,
        @varcost = 
          CASE @iloop
          WHEN 1 THEN @va_unitcost
          WHEN 2 THEN @va_direct
          WHEN 3 THEN @va_overhead
          WHEN 4 THEN @va_utility 
          when 0 then 0
          END


      if @glqty1 = 0								-- mls 2/4/04 SCR 32407
        select @glcost1 = 0
      if @iloop = 0
        select @cost = @glcost1							-- mls 12/6/00 SCR 25339

      Select @glaccount = 
        CASE @iloop
        WHEN 0 THEN @xfer
        WHEN 1 THEN @inv_acct
        WHEN 2 THEN @direct_acct
        WHEN 3 THEN @ovhd_acct
        WHEN 4 THEN @util_acct
      END,
      @glaccount1 = 
        CASE @iloop
        WHEN 0 THEN @xfer
        WHEN 1 THEN @var_mat_acct
        WHEN 2 THEN @var_direct_acct
        WHEN 3 THEN @var_overh_acct
        WHEN 4 THEN @var_utility_acct
      END,
      @line_descr = 
        CASE @iloop
        WHEN 1 THEN 'inv_acct' WHEN 2 THEN 'inv_direct_acct' WHEN 3 THEN 'inv_ovhd_acct' 
        WHEN 4 THEN 'inv_util_acct' ELSE 'xfer_acct' END,
      @line_descr1 = 
        CASE @iloop
        WHEN 1 THEN 'var_mat_acct' WHEN 2 THEN 'var_direct_acct' WHEN 3 THEN 'var_ovhd_acct' 
        WHEN 4 THEN 'var_util_acct' ELSE 'xfer_acct' END

      select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' else '' end -- mls 4/22/02 SCR 28686

      select @gl_loc = case when @iloop = 0 then @i_from_loc else @i_to_loc end
        
      IF @glcost1 != 0 or @iloop = 1
      BEGIN
        select @temp_cost = case when @glqty1 = 0 then 0 else @glcost1 / @glqty1 end	-- mls 6/2/04 SCR 32407
        exec @retval = adm_gl_insert  @i_part_no,@gl_loc,'X',@i_xfer_no,0, @i_line_no,		-- mls 1/24/01 SCR 20787
          @xfers_date_recvd,@glqty1,@temp_cost,@glaccount,@natcode,DEFAULT,DEFAULT, @company_id,
          DEFAULT,DEFAULT,@a_tran_id,  @line_descr, @glcost1, @iloop, DEFAULT, @xfers_to_org_id
        IF @retval <= 0
        BEGIN
          select @msg = 'Error Inserting To Inventory GL Costing Record ([' + convert(varchar,@retval) + '])!' 
          rollback tran
          exec adm_raiserror 97111, @msg
          return
        END
      end

      if @varcost != 0 and @amt_variance != 0							-- mls 2/11/03 SCR 30654 -- mls 6/14/02 Start
      begin 
 	select @varqty = @amt_variance									-- mls 2/11/03 SCR 30654
	select @temp_cost = @varcost / @varqty
        exec @retval = adm_gl_insert @i_part_no,@gl_loc,'X',@i_xfer_no,0, @i_line_no, 
          @xfers_date_recvd,@varqty,@temp_cost,@glaccount1,@natcode,DEFAULT,DEFAULT, @company_id,	-- mls 2/11/03 SCR 30654
          DEFAULT,DEFAULT, @a_tran_id, @line_descr1, @varcost,DEFAULT,DEFAULT, @xfers_to_org_id

        IF @retval <= 0 
        BEGIN 
	  select @msg = 'Error Inserting Variance GL Costing Record ([' + convert(varchar,@retval) + '])!' 
          rollback tran 
          exec adm_raiserror 97112, @msg
          return
        END 

        SELECT @varqty = @amt_variance * (-1), 								-- mls 2/11/03 SCR 30654	
	  @varcost = @varcost * (-1)

        exec @retval = adm_gl_insert @i_part_no,@i_from_loc,'X',@i_xfer_no,0, @i_line_no, 		-- mls 2/11/03 SCR 30654
          @xfers_date_recvd,@varqty,@temp_cost,@xfer,@natcode,DEFAULT,DEFAULT, @company_id ,	-- mls 2/11/03 SCR 30654
          DEFAULT,DEFAULT, @a_tran_id, 'xfer_acct', @varcost,DEFAULT,DEFAULT, @xfers_to_org_id

        IF @retval <= 0 
        BEGIN  
	  select @msg = 'Error Inserting To transfer account GL Costing Record ([' + convert(varchar,@retval) + '])!' 
          rollback tran
          exec adm_raiserror 97113, @msg
          return 
        END  
      end 											-- mls 6/14/02 end

      SELECT @iloop = @iloop + 1
    END --While

    if (@v_unitcost != 0 or @v_direct != 0 or @v_overhead != 0 or @v_utility != 0)
    BEGIN
      select @iloop = 1
      WHILE @iloop <= 4
      BEGIN 
        -- SCR 21423 Check to see if a cost variance exists and update gl if necessary
        Select @variance = 
          CASE @iloop
          WHEN 1 THEN @v_unitcost
          WHEN 2 THEN @v_direct
          WHEN 3 THEN @v_overhead
          WHEN 4 THEN @v_utility 
          END

        -- SCR 21423 If there is a variance then update appropriate cost variance account
        If @variance != 0
        BEGIN
          -- SCR 21423 select appropriate cost variance account
          Select @glaccount = 
            CASE @iloop
            WHEN 1 THEN @cost_var_code
            WHEN 2 THEN @cost_var_dir
            WHEN 3 THEN @cost_var_ovhd
            WHEN 4 THEN @cost_var_util
          END,
          @line_descr = 
            CASE @iloop
            WHEN 1 THEN 'cost_var_acct' WHEN 2 THEN 'cost_var_direct_acct' WHEN 3 THEN 'cost_var_ovhd_acct' 
            WHEN 4 THEN 'cost_var_util_acct' END
 
          select @temp_cost = case when @glqty1 = 0 then 0 else @variance / @glqty1 end 	-- mls 6/2/04 SCR 32407
          exec @retval = adm_gl_insert  @i_part_no,@i_to_loc,'X',@i_xfer_no,0, @i_line_no,		-- mls 1/24/01 SCR 20787
            @xfers_date_recvd,@qty,@temp_cost,@glaccount,@natcode,DEFAULT,DEFAULT, @company_id,
            DEFAULT, DEFAULT, @a_tran_id, @line_descr, @variance
           IF @retval <= 0
          BEGIN
	    select @msg = 'Error Inserting Cost Variance GL Costing Record ([' + convert(varchar,@retval) + '])!' 
            rollback tran
            exec adm_raiserror 97114, @msg
            return
          END
        END --@variance != 0
           
       SELECT @iloop = @iloop + 1
      END --While
    END --(@v_unitcost != 0 or @v_direct != 0 or @v_overhead != 0 or @v_utility != 0)

    if @typ = 'W'											-- mls 5/4/00 SCR 22565 start
    begin
      exec @retval = adm_wavg_cost_var @i_part_no , @i_to_loc , 'X' , @i_xfer_no , 0 ,  @i_line_no,		-- mls 1/24/01 SCR 20787
        @xfers_date_recvd , @o_avg_cost , @o_direct_dolrs , @o_ovhd_dolrs , @o_util_dolrs ,
        @i_avg_cost , @i_direct_dolrs , @i_ovhd_dolrs , @i_util_dolrs , @in_stock , 1, @a_tran_id
               	 
      IF @retval <= 0
      BEGIN
	select @msg = 'Error Inserting GL Costing Record for WAVG variance ([' + convert(varchar,@retval) + '])!' 
        rollback tran
        exec adm_raiserror 91313, @msg
        return
      end
    end												-- mls 5/4/00 SCR 22565 end

  IF (@COGS != 0 ) and @typ != 'S'
    -- if there needs to be a costing adjustment to the COGS accounts and the xfer accounts then
  BEGIN
    -- Get all the COGS account numbers(names)
    SELECT @ar_cgs_code = ar_cgs_code,
      @ar_cgs_direct_code = ar_cgs_direct_code,
      @ar_cgs_ovhd_code = ar_cgs_ovhd_code,
      @ar_cgs_util_code = ar_cgs_util_code
    FROM in_account (nolock)
    WHERE acct_code = @posting_code
                
    -- if the qty went to postive, only use the qty that made it zero
    IF ( @COGS = 2 ) 
    BEGIN
      select @qty = @l_in_stock
    END

    SELECT @iloop = 1

    WHILE @iloop <= 4
    BEGIN 
      -- cost = the differnce between the costs
      Select @cost = 
        CASE @iloop
          WHEN 1 THEN @c_unitcost
          WHEN 2 THEN @c_direct
          WHEN 3 THEN @c_overhead
          WHEN 4 THEN @c_utility
        END      
      Select @glaccount = 
        CASE @iloop
        WHEN 1 THEN @ar_cgs_code
        WHEN 2 THEN @ar_cgs_direct_code
        WHEN 3 THEN @ar_cgs_ovhd_code
        WHEN 4 THEN @ar_cgs_util_code
      END,
      @line_descr = 
        CASE @iloop
        WHEN 1 THEN 'ar_cgs_acct' WHEN 2 THEN 'ar_cgs_direct_acct' WHEN 3 THEN 'ar_cgs_ovhd_acct' 
        WHEN 4 THEN 'ar_cgs_util_acct' END

      select @line_descr = @line_descr + case @COGS when 1 then ' (- -)' when 2 then ' (- +)' else '' end -- mls 4/22/02 SCR 28686
        
      select @cost = isnull(@cost, 0)  --SCR 22515    

      IF @cost != 0 
      BEGIN
          select @temp_cost = @cost / @qty
          exec @retval = adm_gl_insert  @i_part_no,@i_to_loc,'X',@i_xfer_no,0, @i_line_no,		-- mls 1/24/01 SCR 20787
            @xfers_date_recvd,@qty,@temp_cost,@glaccount,@natcode,DEFAULT,DEFAULT, @company_id,
            DEFAULT, DEFAULT, @a_tran_id, @line_descr, @cost
        IF @retval <= 0
        BEGIN
	  select @msg = 'Error Inserting COGS GL Costing Record ([' + convert(varchar,@retval) + '])!' 
          rollback tran
          exec adm_raiserror 97115, @msg
         return
        END
      END -- @cost != 0

      select @iloop = @iloop + 1
    END -- while @iloop
  end -- @COGS != 0
  END  -- status = 's'

  

  declare @tdc_rtn int, @stat varchar(10)

  select @qty=(@i_shipped * @i_conv_factor)

  SELECT @stat = 'XFERL_UPD'

  exec @tdc_rtn = tdc_xfer_list_change @i_xfer_no, @i_line_no, @i_part_no, @qty, @stat

  if (@tdc_rtn< 0 )
  begin
    exec adm_raiserror 77900 ,'Invalid Inventory Update From TDC.'
  end
  

  FETCH NEXT FROM updxfrl into
  @i_xfer_no, @i_line_no, @i_from_loc, @i_to_loc, @i_part_no, @i_description, @i_time_entered, @i_ordered, 
  @i_shipped, @i_comment, @i_status, @i_cost, @i_com_flag, @i_who_entered, @i_temp_cost, @i_uom, @i_conv_factor, 
  @i_std_cost, @i_from_bin, @i_to_bin, @i_lot_ser, @i_date_expires, @i_lb_tracking, @i_labor, @i_direct_dolrs, 
  @i_ovhd_dolrs, @i_util_dolrs, @i_row_id, @i_display_line, @i_qty_rcvd, @i_reference_code, @i_adj_code ,@i_amt_variance,
  @d_xfer_no, @d_line_no, @d_from_loc, @d_to_loc, @d_part_no, @d_description, @d_time_entered, @d_ordered, 
  @d_shipped, @d_comment, @d_status, @d_cost, @d_com_flag, @d_who_entered, @d_temp_cost, @d_uom, @d_conv_factor, 
  @d_std_cost, @d_from_bin, @d_to_bin, @d_lot_ser, @d_date_expires, @d_lb_tracking, @d_labor, @d_direct_dolrs, 
  @d_ovhd_dolrs, @d_util_dolrs, @d_row_id, @d_display_line, @d_qty_rcvd, @d_reference_code, @d_adj_code, @d_amt_variance  
end 

CLOSE updxfrl
DEALLOCATE updxfrl
END




GO
CREATE NONCLUSTERED INDEX [xferlst2] ON [dbo].[xfer_list] ([from_loc], [part_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [xferlst1] ON [dbo].[xfer_list] ([xfer_no], [line_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[xfer_list] TO [public]
GO
GRANT SELECT ON  [dbo].[xfer_list] TO [public]
GO
GRANT INSERT ON  [dbo].[xfer_list] TO [public]
GO
GRANT DELETE ON  [dbo].[xfer_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[xfer_list] TO [public]
GO
