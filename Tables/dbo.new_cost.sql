CREATE TABLE [dbo].[new_cost]
(
[timestamp] [timestamp] NOT NULL,
[kys] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_level] [char] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[new_amt] [decimal] (20, 8) NOT NULL,
[new_direction] [int] NOT NULL,
[eff_date] [datetime] NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [datetime] NULL,
[reason] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[apply_date] [datetime] NULL,
[apply_qty] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_apply_qty] DEFAULT ((0)),
[prev_unit_cost] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_prev_unit_cost] DEFAULT ((0)),
[prev_direct_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_prev_direct_dolrs] DEFAULT ((0)),
[prev_ovhd_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_prev_ovhd_dolrs] DEFAULT ((0)),
[prev_util_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_prev_util_dolrs] DEFAULT ((0)),
[curr_unit_cost] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_curr_unit_cost] DEFAULT ((0)),
[curr_direct_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_curr_direct_dolrs] DEFAULT ((0)),
[curr_ovhd_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_curr_ovhd_dolrs] DEFAULT ((0)),
[curr_util_dolrs] [decimal] (20, 8) NOT NULL CONSTRAINT [DF_new_cost_curr_util_dolrs] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700delnewcost] ON [dbo].[new_cost]
 FOR DELETE 
AS
begin
if exists (select 1 from config  (nolock) where flag='TRIG_DEL_NEWC' and value_str='DISABLE')	
	return

if exists (select 1 from deleted where status in ('X','P'))	
begin
	rollback tran
	exec adm_raiserror 75499, 'You Can Not Delete A processed NEW_COST record!' 
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700insnewcost] ON [dbo].[new_cost]
 FOR INSERT 
AS
begin
if exists (select 1 from config  (nolock) where flag='TRIG_INS_NEWC' and value_str='DISABLE')	
	return

if exists (select 1 from inserted where status = 'P')	
begin
	rollback tran
	exec adm_raiserror 75499, 'You Can Not Insert NEW_COST records in a processed status!' 
	return
	end
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700updnewcost] ON [dbo].[new_cost] FOR update AS 
BEGIN
if exists (select * from config (nolock) where flag='TRIG_INS_NEWC' and value_str='DISABLE')  RETURN

if update(part_no) or update(location) 
begin
  rollback tran
  exec adm_raiserror 93131 ,'You Can Not Change A Part Number or A Location!'
  return
end 

DECLARE @company_id int, @natcode varchar(8), @inv_exists int, @typ char(1)
DECLARE @acct_code varchar(8), @inv_acct varchar(32), @account varchar(32)
DECLARE @inv_direct varchar(32),@inv_ovhd varchar(32), @inv_util varchar(32), @std_inc varchar(32)
DECLARE @inc_direct varchar(32),@inc_ovhd varchar(32), @inc_util varchar(32), @std_dec varchar(32)
DECLARE @dec_direct varchar(32),@dec_ovhd varchar(32), @dec_util varchar(32), @iloop int,
  @cost decimal(20,8), @retval int

declare @line_descr varchar(50)							-- mls 4/25/02 SCR 28686
declare @a_tran_id int, @COGS int, @msg varchar(255), @in_stock decimal(20,8)
declare @m_status char(1)

DECLARE @i_kys int, @i_location varchar(10), @i_part_no varchar(30), @i_cost_level char(4),
@i_new_type char(1), @i_new_amt decimal(20,8), @i_new_direction int, @i_eff_date datetime,
@i_who_entered varchar(20), @i_date_entered datetime, @i_reason varchar(20), @i_status char(1),
@i_note varchar(255), @i_row_id int, @i_apply_date datetime, @i_apply_qty decimal(20,8),
@i_prev_unit_cost decimal(20,8), @i_prev_direct_dolrs decimal(20,8),
@i_prev_ovhd_dolrs decimal(20,8), @i_prev_util_dolrs decimal(20,8),
@i_curr_unit_cost decimal(20,8), @i_curr_direct_dolrs decimal(20,8),
@i_curr_ovhd_dolrs decimal(20,8), @i_curr_util_dolrs decimal(20,8),
@d_kys int, @d_location varchar(10), @d_part_no varchar(30), @d_cost_level char(4),
@d_new_type char(1), @d_new_amt decimal(20,8), @d_new_direction int, @d_eff_date datetime,
@d_who_entered varchar(20), @d_date_entered datetime, @d_reason varchar(20), @d_status char(1),
@d_note varchar(255), @d_row_id int, @d_apply_date datetime, @d_apply_qty decimal(20,8),
@d_prev_unit_cost decimal(20,8), @d_prev_direct_dolrs decimal(20,8),
@d_prev_ovhd_dolrs decimal(20,8), @d_prev_util_dolrs decimal(20,8),
@d_curr_unit_cost decimal(20,8), @d_curr_direct_dolrs decimal(20,8),
@d_curr_ovhd_dolrs decimal(20,8), @d_curr_util_dolrs decimal(20,8)

declare @unitcost decimal(20,8), @direct decimal(20,8), @overhead decimal(20,8), @utility decimal(20,8),
  @labor decimal(20,8), @a_tran_info int, @a_tran_data varchar(255)

DECLARE t700updnew__cursor CURSOR LOCAL STATIC FOR
SELECT i.kys, i.location, i.part_no, i.cost_level, i.new_type, i.new_amt, i.new_direction,
i.eff_date, i.who_entered, i.date_entered, i.reason, i.status, i.note, i.row_id, i.apply_date,
i.apply_qty, i.prev_unit_cost, i.prev_direct_dolrs, i.prev_ovhd_dolrs, i.prev_util_dolrs,
i.curr_unit_cost, i.curr_direct_dolrs, i.curr_ovhd_dolrs, i.curr_util_dolrs,
d.kys, d.location, d.part_no, d.cost_level, d.new_type, d.new_amt, d.new_direction,
d.eff_date, d.who_entered, d.date_entered, d.reason, d.status, d.note, d.row_id, d.apply_date,
d.apply_qty, d.prev_unit_cost, d.prev_direct_dolrs, d.prev_ovhd_dolrs, d.prev_util_dolrs,
d.curr_unit_cost, d.curr_direct_dolrs, d.curr_ovhd_dolrs, d.curr_util_dolrs, 
  case when m.inv_cost_method in ('1','2','3','4','5','6','7','8','9') then 'W' 
  when m.inv_cost_method not in ('A','L','F','S') then 'A' else m.inv_cost_method end
from inserted i, deleted d, inv_master m (nolock)
where i.row_id=d.row_id and i.part_no = m.part_no

OPEN t700updnew__cursor
FETCH NEXT FROM t700updnew__cursor into
@i_kys, @i_location, @i_part_no, @i_cost_level, @i_new_type, @i_new_amt, @i_new_direction,
@i_eff_date, @i_who_entered, @i_date_entered, @i_reason, @i_status, @i_note, @i_row_id,
@i_apply_date, @i_apply_qty, @i_prev_unit_cost, @i_prev_direct_dolrs, @i_prev_ovhd_dolrs,
@i_prev_util_dolrs, @i_curr_unit_cost, @i_curr_direct_dolrs, @i_curr_ovhd_dolrs,
@i_curr_util_dolrs,
@d_kys, @d_location, @d_part_no, @d_cost_level, @d_new_type, @d_new_amt, @d_new_direction,
@d_eff_date, @d_who_entered, @d_date_entered, @d_reason, @d_status, @d_note, @d_row_id,
@d_apply_date, @d_apply_qty, @d_prev_unit_cost, @d_prev_direct_dolrs, @d_prev_ovhd_dolrs,
@d_prev_util_dolrs, @d_curr_unit_cost, @d_curr_direct_dolrs, @d_curr_ovhd_dolrs,
@d_curr_util_dolrs, @m_status

While @@FETCH_STATUS = 0
begin
  if @d_status = 'P' and @i_status != 'P'
  begin
    exec adm_raiserror 93101 ,'Error... You cannot change the status of a Processed new cost record!'
    ROLLBACK TRANSACTION
    RETURN
  end

  if @m_status in ('W','S') and @i_status not in ( 'P', 'N' )   -- mls 1/28/08
  begin
    if exists (SELECT 1 FROM inv_list (nolock) 
      WHERE part_no = @i_part_no and location = @i_location)
    begin

      select @i_apply_date = isnull(@i_apply_date,getdate())
      select 
        @unitcost = @i_prev_unit_cost * @i_apply_qty,
        @direct = @i_prev_direct_dolrs * @i_apply_qty,
        @overhead = @i_prev_ovhd_dolrs * @i_apply_qty,
        @utility = @i_prev_util_dolrs * @i_apply_qty

      select @a_tran_info = 2000002

      if @i_curr_unit_cost != @i_prev_unit_cost select @a_tran_info = @a_tran_info + 10000
      if @i_curr_direct_dolrs != @i_prev_direct_dolrs select @a_tran_info = @a_tran_info + 1000
      if @i_curr_ovhd_dolrs != @i_prev_direct_dolrs select @a_tran_info = @a_tran_info + 100
      if @i_curr_util_dolrs != @i_prev_direct_dolrs select @a_tran_info = @a_tran_info + 10
      select @a_tran_data = @a_tran_info 
     
      exec @retval = adm_inv_tran 
        'N', @i_kys, 0, @i_row_id, @i_part_no, @i_location, @i_apply_qty, @i_apply_date, '', 
        1, @i_status,@a_tran_data, DEFAULT, 
        @a_tran_id OUT, @i_curr_unit_cost OUT, @i_curr_direct_dolrs OUT, @i_curr_ovhd_dolrs OUT, @i_curr_util_dolrs OUT,
        0,
        @COGS OUT, @unitcost OUT, @direct OUT, @overhead OUT, @utility OUT, 0,
	@in_stock OUT

      if @retval <> 1
      begin
        rollback tran
        select @msg = 'Error ([' + convert(varchar(10), @retval) + ']) returned from adm_inv_tran.'
        exec adm_raiserror 83202 ,@msg
        RETURN
      end
    end

  end

FETCH NEXT FROM t700updnew__cursor into
@i_kys, @i_location, @i_part_no, @i_cost_level, @i_new_type, @i_new_amt, @i_new_direction,
@i_eff_date, @i_who_entered, @i_date_entered, @i_reason, @i_status, @i_note, @i_row_id,
@i_apply_date, @i_apply_qty, @i_prev_unit_cost, @i_prev_direct_dolrs, @i_prev_ovhd_dolrs,
@i_prev_util_dolrs, @i_curr_unit_cost, @i_curr_direct_dolrs, @i_curr_ovhd_dolrs,
@i_curr_util_dolrs,
@d_kys, @d_location, @d_part_no, @d_cost_level, @d_new_type, @d_new_amt, @d_new_direction,
@d_eff_date, @d_who_entered, @d_date_entered, @d_reason, @d_status, @d_note, @d_row_id,
@d_apply_date, @d_apply_qty, @d_prev_unit_cost, @d_prev_direct_dolrs, @d_prev_ovhd_dolrs,
@d_prev_util_dolrs, @d_curr_unit_cost, @d_curr_direct_dolrs, @d_curr_ovhd_dolrs,
@d_curr_util_dolrs, @m_status
end -- while

CLOSE t700updnew__cursor
DEALLOCATE t700updnew__cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [newcost1] ON [dbo].[new_cost] ([kys], [location], [part_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [missing_index_219781_219780_new_cost] ON [dbo].[new_cost] ([location], [part_no], [status], [curr_unit_cost], [curr_direct_dolrs], [curr_ovhd_dolrs], [curr_util_dolrs], [new_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[new_cost] TO [public]
GO
GRANT SELECT ON  [dbo].[new_cost] TO [public]
GO
GRANT INSERT ON  [dbo].[new_cost] TO [public]
GO
GRANT DELETE ON  [dbo].[new_cost] TO [public]
GO
GRANT UPDATE ON  [dbo].[new_cost] TO [public]
GO
