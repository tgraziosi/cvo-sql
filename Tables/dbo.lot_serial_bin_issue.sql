CREATE TABLE [dbo].[lot_serial_bin_issue]
(
[timestamp] [timestamp] NOT NULL,
[line_no] [int] NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NULL,
[qty] [decimal] (20, 8) NOT NULL,
[direction] [int] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[conv_factor] [decimal] (20, 8) NULL,
[who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cost] [decimal] (20, 8) NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [decimal] (20, 8) NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[lot_serial_bin_issue_del] ON [dbo].[lot_serial_bin_issue]
FOR DELETE
AS

BEGIN

if not exists ( select * from config where flag='INV_LOT_BIN' and value_str = 'YES' )
return

DECLARE 
@d_line_no int, @d_tran_no int, @d_tran_ext int, @d_part_no varchar(30), @d_location varchar(10), 
@d_bin_no varchar(12), @d_tran_code char(1), @d_date_tran datetime, @d_date_expires datetime, 
@d_qty decimal(20,8), @d_direction smallint, @d_uom char(2), @d_conv_factor decimal(20,8),
@d_who varchar(20), @d_cost decimal(20,8), @d_lot_ser varchar(25), @d_uom_qty decimal(20,8),
@h_issue_no int

DECLARE t700dellot__cursor CURSOR LOCAL FOR
select d.line_no,d.tran_no,d.tran_ext,d.part_no,d.location,d.bin_no,d.tran_code,d.date_tran,
d.date_expires,d.qty,d.direction,d.uom,d.conv_factor,d.who,d.cost,d.lot_ser,d.uom_qty,
h.issue_no
from deleted d
left outer join issues_all h
on h.issue_no = d.tran_no
order by d.tran_no

OPEN t700dellot__cursor
FETCH NEXT FROM t700dellot__cursor into
@d_line_no, @d_tran_no, @d_tran_ext, @d_part_no, @d_location, @d_bin_no, @d_tran_code, @d_date_tran, 
@d_date_expires, @d_qty, @d_direction, @d_uom, @d_conv_factor, @d_who, @d_cost, @d_lot_ser, @d_uom_qty,
@h_issue_no

While @@FETCH_STATUS = 0
begin
  if @h_issue_no is not null
  begin
    if not exists ( select 1 from config (nolock) where flag='TRIG_LSBI' and value_str = 'DISABLE' )
    begin
      rollback tran
      exec adm_raiserror 83231, 'Error deleting lot_serial_bin_issue record.  Issue already exists!'
      return
    end
  end

if (@d_qty * @d_direction) < 0
begin
 insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
 select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code,
 @d_tran_no, 0, 				-- mls 4/20/01 SCR 26762
 @d_date_tran, @d_date_expires, @d_qty, @d_direction * -1, isnull(@d_cost,0), 'NA', 0, 0, 0, @d_who
end

if (@d_qty * @d_direction) > 0
begin
 insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
 select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code,
 @d_tran_no, 0, 				-- mls 4/20/01 SCR 26762
 @d_date_tran, @d_date_expires, @d_qty, @d_direction * -1, isnull(@d_cost,0), 'NA', 0, 0, 0, @d_who
end

FETCH NEXT FROM t700dellot__cursor into
@d_line_no, @d_tran_no, @d_tran_ext, @d_part_no, @d_location, @d_bin_no, @d_tran_code, @d_date_tran, 
@d_date_expires, @d_qty, @d_direction, @d_uom, @d_conv_factor, @d_who, @d_cost, @d_lot_ser, @d_uom_qty,
@h_issue_no
end

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



--  Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[lot_serial_bin_issue_ins] ON [dbo].[lot_serial_bin_issue]
FOR INSERT
AS
BEGIN

if not exists ( select 1 from config (nolock) where flag='INV_LOT_BIN' and value_str = 'YES' )
 return

DECLARE 
@i_line_no int, @i_tran_no int, @i_tran_ext int, @i_part_no varchar(30), @i_location varchar(10), 
@i_bin_no varchar(12), @i_tran_code char(1), @i_date_tran datetime, @i_date_expires datetime, 
@i_qty decimal(20,8), @i_direction smallint, @i_uom char(2), @i_conv_factor decimal(20,8),
@i_who varchar(20), @i_cost decimal(20,8), @i_lot_ser varchar(25), @i_uom_qty decimal(20,8),
@h_issue_no int

DECLARE t700inslot__cursor CURSOR LOCAL FOR
select i.line_no,i.tran_no,i.tran_ext,i.part_no,i.location,i.bin_no,i.tran_code,i.date_tran,
i.date_expires,i.qty,i.direction,i.uom,i.conv_factor,i.who,i.cost,i.lot_ser,i.uom_qty,
h.issue_no
from inserted i
left outer join issues_all h
on h.issue_no = i.tran_no
order by i.tran_no

OPEN t700inslot__cursor

if @@cursor_rows = 0
begin
  CLOSE t700inslot__cursor
  DEALLOCATE t700inslot__cursor
  return
end

FETCH NEXT FROM t700inslot__cursor into
@i_line_no, @i_tran_no, @i_tran_ext, @i_part_no, @i_location, @i_bin_no, @i_tran_code, @i_date_tran, 
@i_date_expires, @i_qty, @i_direction, @i_uom, @i_conv_factor, @i_who, @i_cost, @i_lot_ser, @i_uom_qty,
@h_issue_no

While @@FETCH_STATUS = 0
begin
  if @h_issue_no is not null
  begin
    if not exists ( select 1 from config (nolock) where flag='TRIG_LSBI' and value_str = 'DISABLE' )
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Inserting lot_serial_bin_issue record.  Issue already exists!'
      return
    end
  end

  if (@i_qty * @i_direction) > 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser,
       @i_tran_code , 
      @i_tran_no, 0, 
      @i_date_tran, @i_date_expires, @i_qty, @i_direction, isnull(@i_cost,0), 'NA', 0, 0, 0, @i_who
  end
  else
  begin
    
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select  @i_location,  @i_part_no,  @i_bin_no,  @i_lot_ser,
      @i_tran_code,  @i_tran_no, 0, 				-- mls 4/20/01 SCR 26762
      @i_date_tran,  @i_date_expires,  @i_qty,  @i_direction, isnull( @i_cost,0), 'NA', 0, 0, 0,  @i_who
  end

FETCH NEXT FROM t700inslot__cursor into
@i_line_no, @i_tran_no, @i_tran_ext, @i_part_no, @i_location, @i_bin_no, @i_tran_code, @i_date_tran, 
@i_date_expires, @i_qty, @i_direction, @i_uom, @i_conv_factor, @i_who, @i_cost, @i_lot_ser, @i_uom_qty,
@h_issue_no
end

end
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

-- Copyright (c) 1997 Epicor Software, Inc. All Right Reserved.
CREATE TRIGGER [dbo].[lot_serial_bin_issue_upd] ON [dbo].[lot_serial_bin_issue]
FOR UPDATE
AS

BEGIN

if not exists ( select * from config where flag='INV_LOT_BIN' and value_str = 'YES' )
  return

DECLARE 
@i_line_no int, @i_tran_no int, @i_tran_ext int, @i_part_no varchar(30), @i_location varchar(10), 
@i_bin_no varchar(12), @i_tran_code char(1), @i_date_tran datetime, @i_date_expires datetime, 
@i_qty decimal(20,8), @i_direction smallint, @i_uom char(2), @i_conv_factor decimal(20,8),
@i_who varchar(20), @i_cost decimal(20,8), @i_lot_ser varchar(25), @i_uom_qty decimal(20,8),
@d_line_no int, @d_tran_no int, @d_tran_ext int, @d_part_no varchar(30), @d_location varchar(10), 
@d_bin_no varchar(12), @d_tran_code char(1), @d_date_tran datetime, @d_date_expires datetime, 
@d_qty decimal(20,8), @d_direction smallint, @d_uom char(2), @d_conv_factor decimal(20,8),
@d_who varchar(20), @d_cost decimal(20,8), @d_lot_ser varchar(25), @d_uom_qty decimal(20,8),
@h_issue_no int, @h_status char(1)

DECLARE t700updlot__cursor CURSOR LOCAL FOR
select i.line_no,i.tran_no,i.tran_ext,i.part_no,i.location,i.bin_no,i.tran_code,i.date_tran,
i.date_expires,i.qty,i.direction,i.uom,i.conv_factor,i.who,i.cost,i.lot_ser,i.uom_qty,
d.line_no,d.tran_no,d.tran_ext,d.part_no,d.location,d.bin_no,d.tran_code,d.date_tran,
d.date_expires,d.qty,d.direction,d.uom,d.conv_factor,d.who,d.cost,d.lot_ser,d.uom_qty,h.issue_no,
h.status
from inserted i
join deleted d on d.tran_no = i.tran_no and d.tran_ext = i.tran_ext and d.line_no = i.line_no
left outer join issues_all h on h.issue_no = i.tran_no
order by i.tran_no

OPEN t700updlot__cursor
FETCH NEXT FROM t700updlot__cursor into
@i_line_no, @i_tran_no, @i_tran_ext, @i_part_no, @i_location, @i_bin_no, @i_tran_code, @i_date_tran, 
@i_date_expires, @i_qty, @i_direction, @i_uom, @i_conv_factor, @i_who, @i_cost, @i_lot_ser, @i_uom_qty,
@d_line_no, @d_tran_no, @d_tran_ext, @d_part_no, @d_location, @d_bin_no, @d_tran_code, @d_date_tran, 
@d_date_expires, @d_qty, @d_direction, @d_uom, @d_conv_factor, @d_who, @d_cost, @d_lot_ser, @d_uom_qty,
@h_issue_no, @h_status

While @@FETCH_STATUS = 0
begin
  if @h_issue_no is not null  and isnull(@h_status,'S') >= 'S'
  begin
    if not exists ( select 1 from config (nolock) where flag='TRIG_LSBI' and value_str = 'DISABLE' )
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error updating lot_serial_bin_issue record.  Issue already exists!'
      return
    end
  end

  if (@d_qty * @d_direction) < 0 
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code,
    @d_tran_no, 0, 				-- mls 4/20/01 SCR 26762
    @d_date_tran, @d_date_expires, @d_qty, @d_direction * -1, isnull(@d_cost,0), 'NA', 0, 0, 0, @d_who
  end

  if (@i_qty * @i_direction) > 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code,
    @i_tran_no, 0, 				-- mls 4/20/01 SCR 26762
    @i_date_tran, @i_date_expires, @i_qty, @i_direction, isnull(@i_cost,0), 'NA', 0, 0, 0, @i_who
  end

  if (@d_qty * @d_direction) > 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 	
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code,
    @d_tran_no, 0, 				-- mls 4/20/01 SCR 26762
    @d_date_tran, @d_date_expires, @d_qty, @d_direction * -1, isnull(@d_cost,0), 'NA', 0, 0, 0, @d_who
  end

  if (@i_qty * @i_direction) < 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	 tran_no, tran_ext, date_tran, date_expires, qty, direction, 
 	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code,
    @i_tran_no, 0, 				-- mls 4/20/01 SCR 26762
    @i_date_tran, @i_date_expires, @i_qty, @i_direction, isnull( @i_cost,0), 'NA', 0, 0, 0, @i_who
  end

FETCH NEXT FROM t700updlot__cursor into
@i_line_no, @i_tran_no, @i_tran_ext, @i_part_no, @i_location, @i_bin_no, @i_tran_code, @i_date_tran, 
@i_date_expires, @i_qty, @i_direction, @i_uom, @i_conv_factor, @i_who, @i_cost, @i_lot_ser, @i_uom_qty,
@d_line_no, @d_tran_no, @d_tran_ext, @d_part_no, @d_location, @d_bin_no, @d_tran_code, @d_date_tran, 
@d_date_expires, @d_qty, @d_direction, @d_uom, @d_conv_factor, @d_who, @d_cost, @d_lot_ser, @d_uom_qty,
@h_issue_no, @h_status
END

END

GO
CREATE UNIQUE CLUSTERED INDEX [lot_serial_bin_issue_pk] ON [dbo].[lot_serial_bin_issue] ([line_no], [tran_no], [tran_ext]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [lot_serial_bin_issue_idx1] ON [dbo].[lot_serial_bin_issue] ([tran_no]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[lot_serial_bin_issue] ADD CONSTRAINT [lot_serial_bin_issue_locations_fk1] FOREIGN KEY ([location]) REFERENCES [dbo].[locations_all] ([location])
GO
ALTER TABLE [dbo].[lot_serial_bin_issue] ADD CONSTRAINT [lot_serial_bin_issue_inv_master_fk1] FOREIGN KEY ([part_no]) REFERENCES [dbo].[inv_master] ([part_no])
GO
GRANT REFERENCES ON  [dbo].[lot_serial_bin_issue] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_serial_bin_issue] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_serial_bin_issue] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_serial_bin_issue] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_serial_bin_issue] TO [public]
GO
