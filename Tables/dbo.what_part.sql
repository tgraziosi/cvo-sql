CREATE TABLE [dbo].[what_part]
(
[timestamp] [timestamp] NOT NULL,
[asm_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[attrib] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[who_entered] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bench_stock] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[eff_date] [datetime] NULL,
[date_entered] [datetime] NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[constrain] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fixed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[alt_seq_no] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note3] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note4] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[plan_pcs] [decimal] (20, 8) NULL,
[lag_qty] [decimal] (20, 8) NULL,
[cost_pct] [decimal] (20, 8) NULL,
[pool_qty] [decimal] (20, 8) NULL CONSTRAINT [DF__what_part__pool___2E64C1EB] DEFAULT ((1.0)),
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t603delwhat] ON [dbo].[what_part] FOR delete AS 
BEGIN

DECLARE @d_asm_no varchar(30), @d_seq_no varchar(4), @d_part_no varchar(30),
@d_location varchar(10), @d_qty decimal(20,8), @d_attrib decimal(20,8), @d_uom char(2),
@d_active char(1), @d_who_entered varchar(20), @d_bench_stock char(1), @d_eff_date datetime,
@d_date_entered datetime, @d_conv_factor decimal(20,8), @d_constrain char(1), @d_fixed char(1),
@d_alt_seq_no varchar(4), @d_note varchar(255), @d_note2 varchar(255), @d_note3 varchar(255),
@d_note4 varchar(255), @d_plan_pcs decimal(20,8), @d_lag_qty decimal(20,8),
@d_cost_pct decimal(20,8), @d_pool_qty decimal(20,8)

DECLARE t700delwhat_cursor CURSOR LOCAL STATIC FOR
SELECT d.asm_no, d.seq_no, d.part_no, d.location, d.qty, d.attrib, d.uom, d.active,
d.who_entered, d.bench_stock, d.eff_date, d.date_entered, d.conv_factor, d.constrain, d.fixed,
d.alt_seq_no, d.note, d.note2, d.note3, d.note4, d.plan_pcs, d.lag_qty, d.cost_pct, d.pool_qty
from deleted d

OPEN t700delwhat_cursor

if @@cursor_rows = 0
begin
CLOSE t700delwhat_cursor
DEALLOCATE t700delwhat_cursor
return
end

FETCH NEXT FROM t700delwhat_cursor into
@d_asm_no, @d_seq_no, @d_part_no, @d_location, @d_qty, @d_attrib, @d_uom, @d_active,
@d_who_entered, @d_bench_stock, @d_eff_date, @d_date_entered, @d_conv_factor, @d_constrain,
@d_fixed, @d_alt_seq_no, @d_note, @d_note2, @d_note3, @d_note4, @d_plan_pcs, @d_lag_qty,
@d_cost_pct, @d_pool_qty

While @@FETCH_STATUS = 0
begin
  if @d_active = 'F'
  begin
    delete options
     where @d_asm_no = options.part_no and
          @d_part_no = options.feature

    if not exists (select 1 from what_part w where w.asm_no=@d_asm_no and w.active='F')
    begin
      update inv_master set cfg_flag='N'
       where part_no=@d_asm_no and isnull(cfg_flag,'Y') != 'N'
    end
  end

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  FROM produce_all
  WHERE part_no = @d_asm_no and status < 'S' and build_to_bom != 'C'

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  FROM produce_all p, prod_list
  WHERE p.prod_no = prod_list.prod_no and
        p.prod_ext = prod_list.prod_ext and
        prod_list.part_no = @d_asm_no and
        prod_list.constrain = 'C' and prod_list.status < 'S' 
	and p.build_to_bom != 'C'


FETCH NEXT FROM t700delwhat_cursor into
@d_asm_no, @d_seq_no, @d_part_no, @d_location, @d_qty, @d_attrib, @d_uom, @d_active,
@d_who_entered, @d_bench_stock, @d_eff_date, @d_date_entered, @d_conv_factor, @d_constrain,
@d_fixed, @d_alt_seq_no, @d_note, @d_note2, @d_note3, @d_note4, @d_plan_pcs, @d_lag_qty,
@d_cost_pct, @d_pool_qty
end -- while

CLOSE t700delwhat_cursor
DEALLOCATE t700delwhat_cursor

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t603inswhat] ON [dbo].[what_part] FOR insert AS 
BEGIN

DECLARE @i_asm_no varchar(30), @i_seq_no varchar(4), @i_part_no varchar(30),
@i_location varchar(10), @i_qty decimal(20,8), @i_attrib decimal(20,8), @i_uom char(2),
@i_active char(1), @i_who_entered varchar(20), @i_bench_stock char(1), @i_eff_date datetime,
@i_date_entered datetime, @i_conv_factor decimal(20,8), @i_constrain char(1), @i_fixed char(1),
@i_alt_seq_no varchar(4), @i_note varchar(255), @i_note2 varchar(255), @i_note3 varchar(255),
@i_note4 varchar(255), @i_plan_pcs decimal(20,8), @i_lag_qty decimal(20,8),
@i_cost_pct decimal(20,8), @i_pool_qty decimal(20,8), @m_status char(1)

DECLARE t700inswhat_cursor CURSOR LOCAL STATIC FOR
SELECT i.asm_no, i.seq_no, i.part_no, i.location, i.qty, i.attrib, i.uom, i.active,
i.who_entered, i.bench_stock, i.eff_date, i.date_entered, i.conv_factor, i.constrain, i.fixed,
i.alt_seq_no, i.note, i.note2, i.note3, i.note4, i.plan_pcs, i.lag_qty, i.cost_pct, i.pool_qty,
m.status
from inserted i
left outer join inv_master m (nolock) on m.part_no = i.part_no

OPEN t700inswhat_cursor

if @@cursor_rows = 0
begin
CLOSE t700inswhat_cursor
DEALLOCATE t700inswhat_cursor
return
end

FETCH NEXT FROM t700inswhat_cursor into
@i_asm_no, @i_seq_no, @i_part_no, @i_location, @i_qty, @i_attrib, @i_uom, @i_active,
@i_who_entered, @i_bench_stock, @i_eff_date, @i_date_entered, @i_conv_factor, @i_constrain,
@i_fixed, @i_alt_seq_no, @i_note, @i_note2, @i_note3, @i_note4, @i_plan_pcs, @i_lag_qty,
@i_cost_pct, @i_pool_qty, @m_status

While @@FETCH_STATUS = 0
begin
  if @i_asm_no = @i_part_no
  begin
	rollback tran 
	exec adm_raiserror 82331, 'You Can Not Insert A BOM Item That Is The Assembly! Recheck New Items!'
	return
  end

  IF isnull(@m_status,'') = 'C'
  BEGIN
	rollback tran
	exec adm_raiserror 82332 ,'Custom Kit Items can not be a components on a Build Plan.'
	RETURN
  END

  IF isnull(@m_status,'') = 'R' and @i_active = 'M'
  BEGIN
	rollback tran
	exec adm_raiserror 82332, 'A resource cannot be a by product of the production.'
	RETURN
  END

  if @i_active = 'F'
  begin
    update inv_master 
    set cfg_flag='Y'
    where part_no=@i_asm_no and isnull(cfg_flag,'N') != 'Y'
  end

  UPDATE produce_all										-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  WHERE part_no = @i_asm_no and status < 'S' and build_to_bom != 'C'

  UPDATE produce_all										-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  FROM produce_all p, prod_list
  WHERE p.prod_no = prod_list.prod_no and
        p.prod_ext = prod_list.prod_ext and
        prod_list.part_no = @i_asm_no and
        prod_list.constrain = 'C' and prod_list.status < 'S' and p.build_to_bom != 'C'


FETCH NEXT FROM t700inswhat_cursor into
@i_asm_no, @i_seq_no, @i_part_no, @i_location, @i_qty, @i_attrib, @i_uom, @i_active,
@i_who_entered, @i_bench_stock, @i_eff_date, @i_date_entered, @i_conv_factor, @i_constrain,
@i_fixed, @i_alt_seq_no, @i_note, @i_note2, @i_note3, @i_note4, @i_plan_pcs, @i_lag_qty,
@i_cost_pct, @i_pool_qty, @m_status
end -- while

CLOSE t700inswhat_cursor
DEALLOCATE t700inswhat_cursor

END
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[t603updwhat] ON [dbo].[what_part] FOR update AS 
BEGIN

DECLARE @i_asm_no varchar(30), @i_seq_no varchar(4), @i_part_no varchar(30),
@i_location varchar(10), @i_qty decimal(20,8), @i_attrib decimal(20,8), @i_uom char(2),
@i_active char(1), @i_who_entered varchar(20), @i_bench_stock char(1), @i_eff_date datetime,
@i_date_entered datetime, @i_conv_factor decimal(20,8), @i_constrain char(1), @i_fixed char(1),
@i_alt_seq_no varchar(4), @i_note varchar(255), @i_note2 varchar(255), @i_note3 varchar(255),
@i_note4 varchar(255), @i_plan_pcs decimal(20,8), @i_lag_qty decimal(20,8),
@i_cost_pct decimal(20,8), @i_pool_qty decimal(20,8), @i_row_id int,
@d_asm_no varchar(30), @d_seq_no varchar(4), @d_part_no varchar(30),
@d_location varchar(10), @d_qty decimal(20,8), @d_attrib decimal(20,8), @d_uom char(2),
@d_active char(1), @d_who_entered varchar(20), @d_bench_stock char(1), @d_eff_date datetime,
@d_date_entered datetime, @d_conv_factor decimal(20,8), @d_constrain char(1), @d_fixed char(1),
@d_alt_seq_no varchar(4), @d_note varchar(255), @d_note2 varchar(255), @d_note3 varchar(255),
@d_note4 varchar(255), @d_plan_pcs decimal(20,8), @d_lag_qty decimal(20,8),
@d_cost_pct decimal(20,8), @d_pool_qty decimal(20,8), @d_row_id int, @m_status char(1)

DECLARE t700updwhat_cursor CURSOR LOCAL STATIC FOR
SELECT i.asm_no, i.seq_no, i.part_no, i.location, i.qty, i.attrib, i.uom, i.active,
i.who_entered, i.bench_stock, i.eff_date, i.date_entered, i.conv_factor, i.constrain, i.fixed,
i.alt_seq_no, i.note, i.note2, i.note3, i.note4, i.plan_pcs, i.lag_qty, i.cost_pct, i.pool_qty,
i.row_id,
d.asm_no, d.seq_no, d.part_no, d.location, d.qty, d.attrib, d.uom, d.active,
d.who_entered, d.bench_stock, d.eff_date, d.date_entered, d.conv_factor, d.constrain, d.fixed,
d.alt_seq_no, d.note, d.note2, d.note3, d.note4, d.plan_pcs, d.lag_qty, d.cost_pct, d.pool_qty,
d.row_id,
m.status
from inserted i
join deleted d on i.row_id = d.row_id
left outer join inv_master m (nolock) on i.part_no = m.part_no

OPEN t700updwhat_cursor

if @@cursor_rows = 0
begin
CLOSE t700updwhat_cursor
DEALLOCATE t700updwhat_cursor
return
end

FETCH NEXT FROM t700updwhat_cursor into
@i_asm_no, @i_seq_no, @i_part_no, @i_location, @i_qty, @i_attrib, @i_uom, @i_active,
@i_who_entered, @i_bench_stock, @i_eff_date, @i_date_entered, @i_conv_factor, @i_constrain,
@i_fixed, @i_alt_seq_no, @i_note, @i_note2, @i_note3, @i_note4, @i_plan_pcs, @i_lag_qty,
@i_cost_pct, @i_pool_qty, @i_row_id,
@d_asm_no, @d_seq_no, @d_part_no, @d_location, @d_qty, @d_attrib, @d_uom, @d_active,
@d_who_entered, @d_bench_stock, @d_eff_date, @d_date_entered, @d_conv_factor, @d_constrain,
@d_fixed, @d_alt_seq_no, @d_note, @d_note2, @d_note3, @d_note4, @d_plan_pcs, @d_lag_qty,
@d_cost_pct, @d_pool_qty, @d_row_id, @m_status

While @@FETCH_STATUS = 0
begin
  if (@i_asm_no = @i_part_no)
  begin
	rollback tran 
	exec adm_raiserror 92331 ,'You Can Not Insert A BOM Item That Is The Assembly! Recheck New Items!'
	return
  end

  if isnull(@m_status,'') = 'C'
  begin
	rollback tran
	exec adm_raiserror 92332 ,'Custom Kit Items can not be components on Build Plans.'
	RETURN
  END


  if @i_active != @d_active
  begin
    if @i_active != 'V'
    begin
      
      if exists (select 1 from inv_list (nolock) where void='V' and @i_part_no=part_no) 
      begin
	rollback tran 
	exec adm_raiserror 92333 ,'You Can Not Activate A Void Part Number.'
	return
      end
    end

    if @d_active = 'F'
    begin
      if not exists (select 1 from what_part (nolock) where asm_no = @i_asm_no and active = 'F')
      begin
        update inv_master set cfg_flag='N'
        where part_no=@i_asm_no and isnull(cfg_flag,'Y') != 'N' 
      end
    end
    if @i_active = 'F'
    begin
      update inv_master set cfg_flag='Y'
      where part_no=@i_asm_no and isnull(cfg_flag,'N') != 'Y'
    end

    IF isnull(@m_status,'') = 'R' and @i_active = 'M'
    BEGIN
	  rollback tran
	  exec adm_raiserror 82332, 'A resource cannot be a by product of the production.'
	  RETURN
    END

  end

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  WHERE part_no = @i_asm_no and status < 'S' and build_to_bom != 'C'

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  FROM produce_all p, prod_list
  WHERE p.prod_no = prod_list.prod_no and
        p.prod_ext = prod_list.prod_ext and
        prod_list.part_no = @i_asm_no and
        prod_list.constrain = 'C' and prod_list.status < 'S'
	and p.build_to_bom != 'C'

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  WHERE part_no = @d_asm_no and status < 'S' and build_to_bom != 'C'

  UPDATE produce_all									-- mls 3/15/01 SCR 26284
  SET build_to_bom = 'C'
  FROM produce_all p, prod_list
  WHERE p.prod_no = prod_list.prod_no and
        p.prod_ext = prod_list.prod_ext and
        prod_list.part_no = @d_asm_no and
        prod_list.constrain = 'C' and prod_list.status < 'S'
	and p.build_to_bom != 'C'


FETCH NEXT FROM t700updwhat_cursor into
@i_asm_no, @i_seq_no, @i_part_no, @i_location, @i_qty, @i_attrib, @i_uom, @i_active,
@i_who_entered, @i_bench_stock, @i_eff_date, @i_date_entered, @i_conv_factor, @i_constrain,
@i_fixed, @i_alt_seq_no, @i_note, @i_note2, @i_note3, @i_note4, @i_plan_pcs, @i_lag_qty,
@i_cost_pct, @i_pool_qty, @i_row_id,
@d_asm_no, @d_seq_no, @d_part_no, @d_location, @d_qty, @d_attrib, @d_uom, @d_active,
@d_who_entered, @d_bench_stock, @d_eff_date, @d_date_entered, @d_conv_factor, @d_constrain,
@d_fixed, @d_alt_seq_no, @d_note, @d_note2, @d_note3, @d_note4, @d_plan_pcs, @d_lag_qty,
@d_cost_pct, @d_pool_qty, @d_row_id, @m_status
end -- while

CLOSE t700updwhat_cursor
DEALLOCATE t700updwhat_cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [what1] ON [dbo].[what_part] ([asm_no], [seq_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[what_part] TO [public]
GO
GRANT SELECT ON  [dbo].[what_part] TO [public]
GO
GRANT INSERT ON  [dbo].[what_part] TO [public]
GO
GRANT DELETE ON  [dbo].[what_part] TO [public]
GO
GRANT UPDATE ON  [dbo].[what_part] TO [public]
GO
