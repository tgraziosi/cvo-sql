CREATE TABLE [dbo].[lot_bin_xfer]
(
[timestamp] [timestamp] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_code] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tran_no] [int] NOT NULL,
[tran_ext] [int] NOT NULL,
[date_tran] [datetime] NOT NULL,
[date_expires] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[direction] [smallint] NOT NULL,
[cost] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [decimal] (20, 8) NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[line_no] [int] NOT NULL,
[who] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty_received] [decimal] (20, 8) NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500dellbxfer] ON [dbo].[lot_bin_xfer]   FOR DELETE AS 
BEGIN

DECLARE @d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_to_bin varchar(12), @d_qty_received decimal(20,8),

@l_status char(1), @disable_ind int

DECLARE t700dellot__cursor CURSOR LOCAL STATIC FOR
SELECT d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.to_bin, d.qty_received
from deleted d

OPEN t700dellot__cursor

if @@cursor_rows = 0
begin
CLOSE t700dellot__cursor
DEALLOCATE t700dellot__cursor
return
end

select @disable_ind = isnull((select 1 from config (nolock) where flag='TRIG_LBX' and value_str = 'DISABLE' ),0)

FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_to_bin, @d_qty_received

While @@FETCH_STATUS = 0
begin

  if @d_tran_code >= 'R'
  BEGIN
    rollback tran
    exec adm_raiserror 77999 ,'Transfer Already Shipped.  Can Not Change.'
    return
  END

    select @l_status = isnull((select status
    from xfer_list l where l.xfer_no = @d_tran_no 
      and l.line_no = @d_line_no and l.part_no = @d_part_no and l.from_loc = @d_location),'')

    if @l_status >= 'S' and @l_status < 'V' and @disable_ind = 0
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Deleting lot_bin_xfer record.  Transfer line is already shipped/posted'
      return
    end

  if @d_qty != 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'T', @d_tran_no, @d_tran_ext,
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, 
        (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who 
  end
 
FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_to_bin, @d_qty_received
end -- while

CLOSE t700dellot__cursor
DEALLOCATE t700dellot__cursor


END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslbxfer] ON [dbo].[lot_bin_xfer]   FOR INSERT  AS 
BEGIN

DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),
@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,
@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,
@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),
@i_line_no int, @i_who varchar(20), @i_to_bin varchar(12), @i_qty_received decimal(20,8)

declare @l_status char(1), @disable_ind int

DECLARE t700inslot__cursor CURSOR LOCAL STATIC FOR
SELECT i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,
i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,
i.line_no, i.who, i.to_bin, i.qty_received
from inserted i

OPEN t700inslot__cursor

if @@cursor_rows = 0
begin
CLOSE t700inslot__cursor
DEALLOCATE t700inslot__cursor
return
end

select @disable_ind = isnull((select 1 from config (nolock) where flag='TRIG_LBX' and value_str = 'DISABLE' ),0)

FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_to_bin, @i_qty_received

While @@FETCH_STATUS = 0
begin
    select @l_status = isnull((select status
    from xfer_list l where l.xfer_no = @i_tran_no
      and l.line_no = @i_line_no and l.part_no = @i_part_no and l.from_loc = @i_location),'')

    if @l_status = ''
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Inserting lot_bin_xfer record.  Transfer line for part does not exist'
      return
    end
    if @l_status >= 'R' and @i_tran_code <= @l_status  and @disable_ind = 0
    begin
      rollback tran
      exec adm_raiserror 83231 ,'Error Inserting lot_bin_xfer record.  Transfer line is already shipped'
      return
    end

  
  insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
   select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'T', @i_tran_no, @i_tran_ext,
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who 

  
  if @i_tran_code >= 'S' and @i_tran_code <= 'T'
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select x.to_loc, @i_part_no, @i_to_bin, @i_lot_ser, 'T', @i_tran_no, @i_tran_ext,
	@i_date_tran, @i_date_expires, (@i_qty_received * @i_conv_factor) , (@i_direction*(-1)), 	-- mls 2/11/03 SCR 30654
	@i_cost, @i_uom, @i_qty_received ,								-- mls 2/11/03 SCR 30654
        @i_conv_factor, @i_line_no, @i_who 
    from xfer_list x
    where @i_tran_no=x.xfer_no and @i_line_no=x.line_no 
  end

FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_to_bin, @i_qty_received
end -- while

CLOSE t700inslot__cursor
DEALLOCATE t700inslot__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700updlbxfer] ON [dbo].[lot_bin_xfer]   FOR UPDATE  AS 
BEGIN


DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),
@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,
@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,
@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),
@i_line_no int, @i_who varchar(20), @i_to_bin varchar(12), @i_qty_received decimal(20,8),
@i_row_id int,
@d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_to_bin varchar(12), @d_qty_received decimal(20,8),
@d_row_id int,

@inv_lot_bin int, @l_status char(1), @disable_ind int

DECLARE t700updlot__cursor CURSOR LOCAL STATIC FOR
SELECT i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,
i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,
i.line_no, i.who, i.to_bin, i.qty_received, i.row_id,
d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.to_bin, d.qty_received, d.row_id
from inserted i, deleted d
where i.row_id = d.row_id


OPEN t700updlot__cursor

if @@cursor_rows = 0
begin
CLOSE t700updlot__cursor
DEALLOCATE t700updlot__cursor
return
end

select @inv_lot_bin = isnull((select 1 from config (nolock) where flag='INV_LOT_BIN' and upper(value_str) = 'YES' ),0)
select @disable_ind = isnull((select 1 from config (nolock) where flag='TRIG_LBX' and value_str = 'DISABLE' ),0)

FETCH NEXT FROM t700updlot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_to_bin, @i_qty_received, @i_row_id,
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_to_bin, @d_qty_received, @d_row_id

While @@FETCH_STATUS = 0
begin

  if @d_tran_code >= 'S' 
  BEGIN
    rollback tran
    exec adm_raiserror 97931, 'Transfer Already Shipped/Received.  Can Not Change.'
    return
  END

  select @l_status = isnull((select status
  from xfer_list l where l.xfer_no = @i_tran_no
    and l.line_no = @i_line_no and l.part_no = @i_part_no and l.from_loc = @i_location),'')

  if @l_status = ''
  begin
    rollback tran
    exec adm_raiserror 83231, 'Error Updating lot_bin_xfer record.  Order line for part does not exist'
    return
  end
  if @l_status >= 'R' and 
    (@i_tran_code <= @l_status  and 
      (@d_qty != @i_qty or @d_uom_qty != @i_uom_qty or @d_direction != @i_direction) ) and @disable_ind = 0
  begin
    rollback tran
    exec adm_raiserror 83231 ,'Error Updating lot_bin_xfer record.  Transfer line is already shipped/posted'
    return
  end


  
  if @d_direction < 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'T', @d_tran_no, @d_tran_ext,
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who 
  end

  if @i_direction < 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'T', @i_tran_no, @i_tran_ext,
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who 
  end

  if @i_direction > 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'T', @i_tran_no, @i_tran_ext,
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who
  end

  if @d_direction > 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'T', @d_tran_no, @d_tran_ext,
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who 
  end

  
  if @inv_lot_bin = 1 and (@i_tran_code>='S' and @i_tran_code<='T')
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
		tran_no, tran_ext, date_tran, date_expires, qty, direction, 
		cost, uom, uom_qty, conv_factor, line_no, who)
    select x.to_loc, @i_part_no, @i_to_bin, @i_lot_ser, 'T', @i_tran_no, @i_tran_ext,
		@i_date_tran, @i_date_expires, (@i_qty_received * @i_conv_factor) , 
                (@i_direction*(-1)), 	-- mls 2/11/03 SCR 30654
		@i_cost, @i_uom, @i_qty_received ,								-- mls 2/11/03 SCR 30654
		@i_conv_factor, @i_line_no, @i_who 
    from xfer_list x
    where @i_tran_no=x.xfer_no and @i_line_no=x.line_no
  end


FETCH NEXT FROM t700updlot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_to_bin, @i_qty_received, @i_row_id,
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_to_bin, @d_qty_received, @d_row_id
end -- while

CLOSE t700updlot__cursor
DEALLOCATE t700updlot__cursor

END
GO
CREATE NONCLUSTERED INDEX [lbxfr2] ON [dbo].[lot_bin_xfer] ([location], [part_no], [bin_no], [lot_ser], [tran_no], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [lot_bin_xfer_row_id] ON [dbo].[lot_bin_xfer] ([row_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [lbxfr1] ON [dbo].[lot_bin_xfer] ([tran_no], [line_no], [location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[lot_bin_xfer] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_xfer] TO [public]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_xfer] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_xfer] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_xfer] TO [public]
GO
