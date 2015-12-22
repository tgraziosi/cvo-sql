CREATE TABLE [dbo].[lot_bin_recv]
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
[who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__lot_bin_r__qc_fl__1487EFE9] DEFAULT ('N'),
[row_id] [int] NOT NULL IDENTITY(1, 1),
[receipt_batch_no] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500dellbrecv] ON [dbo].[lot_bin_recv]   FOR DELETE AS 
BEGIN

declare @ordext int, @ordno int, @line_no int, @po varchar(16), @xlp int,
  @rel_date datetime, @po_line int

DECLARE @d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_qc_flag char(1), @d_row_id int, @d_receipt_batch_no int,
@rcpt_qty decimal(20,8), @rcpt_no int

select @rcpt_qty = 0, @rcpt_no = -1

DECLARE t700dellot__cursor CURSOR LOCAL STATIC FOR
SELECT d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.qc_flag, d.row_id, d.receipt_batch_no
from deleted d
order by d.tran_no

OPEN t700dellot__cursor
FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_receipt_batch_no

While @@FETCH_STATUS = 0
begin
  if @rcpt_no < 0 
    select @rcpt_no = @d_tran_no

  if @rcpt_no != @d_tran_no
  begin
    -- update the receipt with the qty from the lot bin record deleted unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty
    where receipt_no = @rcpt_no
  
    select @rcpt_qty = 0, @rcpt_no = @d_tran_no
  end
  else
    select @rcpt_qty =  @rcpt_qty - @d_uom_qty					-- mls 9/7/06 SCR 36973



	select @po=r.po_no,
        @rel_date = r.release_date,		-- mls 12/11/02 SCR 30429	
        @po_line = r.po_line			-- mls 12/11/02 SCR 30429
	from   receipts_all r (nolock)
	where  r.receipt_no= @d_tran_no

        select @line_no = isnull((select ord_line 
        from releases (nolock)			-- mls 12/11/02 SCR 30429 start
        where po_no = @po and release_date = @rel_date and po_line = @po_line),NULL)

        select @ordno = NULL
        if @line_no is not NULL
        begin
	  select @ordno=oap.order_no
	  from orders_auto_po oap (nolock)
          where oap.po_no=@po and oap.part_no = @d_part_no and oap.line_no = @line_no
        end											-- mls 12/11/02 SCR 30429 end

	if isnull(@ordno,0) <> 0				
	Begin
		select @ordext=(select max(ext) from orders_all (nolock) where order_no=@ordno)

		UPDATE lot_bin_ship
		SET    lot_bin_ship.uom_qty=lot_bin_ship.uom_qty - @d_uom_qty,
		       lot_bin_ship.qty=lot_bin_ship.qty - @d_qty
		FROM   lot_bin_ship
		WHERE  lot_bin_ship.tran_no=@ordno and lot_bin_ship.tran_ext=@ordext and
		       lot_bin_ship.line_no=@line_no and lot_bin_ship.lot_ser= @d_lot_ser and
	               lot_bin_ship.bin_no= @d_bin_no	 					-- mls 7/27/99 SCR 70 19958
	       
		DELETE lot_bin_ship
		WHERE tran_no=@ordno and tran_ext=@ordext and line_no=@line_no and qty=0 and uom_qty=0
	end

  if @d_qty != 0
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who) 
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 
        case when @d_qc_flag = 'Y' then 'Q' else 'R' end, @d_tran_no, @d_tran_ext,	-- mls 4/23/02 SCR 28797
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who						-- mls 7/26/00 SCR 23628
  end

FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @d_receipt_batch_no
end -- while

  if @rcpt_no > -1
  begin
    -- update the receipt with the qty from the lot bin record deleted unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty
    where receipt_no = @rcpt_no
  end

CLOSE t700dellot__cursor
DEALLOCATE t700dellot__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslbrecv] ON [dbo].[lot_bin_recv] FOR insert AS 
BEGIN
DECLARE @error varchar(255), @i_ret_val int
-- 9/98- RAF - Lot/Bin DropShip logic.
-- 4/23/02 - MLS - SCR 28797 - check qc held serial parts for duplicates

DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),
@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,
@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,
@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),
@i_line_no int, @i_who varchar(20), @i_qc_flag char(1), @i_row_id int,
@rcpt_qty decimal(20,8), @rcpt_no int, @r_qc_flag char(1)

declare @temp_qty decimal(20,8)

select @rcpt_qty = 0, @rcpt_no = -1

DECLARE t700inslot__cursor CURSOR LOCAL FOR
SELECT i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,
i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,
i.line_no, i.who, i.qc_flag, i.row_id,
r.qc_flag
from inserted i
left outer join receipts_all r (nolock) on r.receipt_no = i.tran_no
order by i.tran_no, i.row_id

OPEN t700inslot__cursor
FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id,
@r_qc_flag
While @@FETCH_STATUS = 0
begin
  select @temp_qty = round((@i_uom_qty * @i_conv_factor),8)
  if @i_qty != @temp_qty
  BEGIN
    rollback tran
    exec adm_raiserror 83221, 'Inventory Qty does not relate to Unit of Measure Quantity on Inserted Lot bin Recv record.'
    return
  END

  if isnull(@r_qc_flag,'') = 'Y'
  begin
    rollback tran
    exec adm_raiserror 83222 ,'Cannot add lot bin recv records to a receipt on QC hold.  Enter new Receipt.'
    return
  end

  if @rcpt_no < 0 
    select @rcpt_no = @i_tran_no

  if @rcpt_no != @i_tran_no
  begin
    -- update the receipt with the qty from the lot bin record inserted unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty
    where receipt_no = @rcpt_no
  
    select @rcpt_qty = 0, @rcpt_no = @i_tran_no
  end
  else
    select @rcpt_qty =  @rcpt_qty + @i_qty


  insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
    tran_no, tran_ext, date_tran, date_expires, qty, direction, 
    cost, uom, uom_qty, conv_factor, line_no, who)
  select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 
    case @i_qc_flag when 'Y' then 'Q' else 'R' end, @i_tran_no, @i_tran_ext,		-- mls 4/23/02 SCR 28797
    @i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
    @i_conv_factor, @i_line_no, @i_who

  if @i_qc_flag = 'Y'
  begin
    update qc_results set lot_ser= @i_lot_ser, bin_no= @i_bin_no 
    from receipts_all where receipt_no= @i_tran_no and qc_results.qc_no=receipts_all.qc_no
  end -- @i_qc_flag = 'Y'

FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id,
@r_qc_flag
end -- while

  if @rcpt_no > -1
  begin
    -- update the receipt with the qty from the lot bin record inserted unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty
    where receipt_no = @rcpt_no
  end

CLOSE t700inslot__cursor
DEALLOCATE t700inslot__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700updlbrecv] ON [dbo].[lot_bin_recv] FOR UPDATE AS 
BEGIN

-- 9/98- RAF - Lot/Bin DropShip logic.
-- 7/27/99 - MLS - SCR 70 19558 - totally rewritten to handle drop shipments of serial tracked items
declare @ordext int, @ordno int, @line_no int, @po varchar(16), @xlp int,
@po_line int, @ord_line int, @rel_date datetime,				-- mls 12/11/02 SCR 30429

@i_location varchar (10) , @i_part_no varchar (30) , @i_bin_no varchar (12) , 
@i_lot_ser varchar (25) , @i_tran_code char (1) , @i_tran_no int , @i_tran_ext int , 
@i_date_tran datetime , @i_date_expires datetime , @i_qty decimal(20, 8) , 
@i_direction smallint , @i_cost decimal(20, 8) , @i_uom char (2), 
@i_uom_qty decimal(20,  8) , @i_conv_factor decimal(20, 8) , @i_line_no int , 
@i_who varchar (20) , @i_qc_flag char (1), @i_row_id int, 
@d_location varchar (10) , @d_part_no varchar (30) , @d_bin_no varchar (12) , 
@d_lot_ser varchar (25) , @d_tran_code char (1) , @d_tran_no int , @d_tran_ext int , 
@d_date_tran datetime , @d_date_expires datetime , @d_qty decimal(20, 8) , 
@d_direction smallint , @d_cost decimal(20, 8) , @d_uom char (2), 
@d_uom_qty decimal(20,  8) , @d_conv_factor decimal(20, 8) , @d_line_no int , 
@d_who varchar (20) , @d_qc_flag char (1), @d_row_id int ,

@rcpt_qty decimal(20,8), @rcpt_no int

declare @max_to_ship decimal(20,8), @l_qty decimal(20,8), @oap_status char(1),
  @temp_qty decimal(20,8), @rcpt_qc_flag char(1)

select @rcpt_qty = 0, @rcpt_no = -1, @rcpt_qc_flag = ''

DECLARE updlbrecv CURSOR LOCAL FOR
select 
  i.location  , i.part_no  , i.bin_no  , i.lot_ser  , i.tran_code  , i.tran_no  , i.tran_ext  ,  
  i.date_tran  , i.date_expires  , i.qty  , i.direction  , i.cost  , i.uom , 
  i.uom_qty  , i.conv_factor  , i.line_no  , i.who  , i.qc_flag , i.row_id , 
  d.location  , d.part_no  , d.bin_no  , d.lot_ser  , d.tran_code  , d.tran_no  , d.tran_ext  , 
  d.date_tran  , d.date_expires  , d.qty  , d.direction  , d.cost  , d.uom , 
  d.uom_qty  , d.conv_factor  , d.line_no  , d.who  , d.qc_flag , d.row_id  
from inserted i
join deleted d on i.row_id = d.row_id
order by i.tran_no

OPEN updlbrecv
FETCH NEXT FROM updlbrecv INTO
  @i_location  , @i_part_no  , @i_bin_no  , @i_lot_ser  , @i_tran_code  , @i_tran_no  , @i_tran_ext  , 
  @i_date_tran  , @i_date_expires  , @i_qty  , @i_direction  , @i_cost  , @i_uom , 
  @i_uom_qty  , @i_conv_factor  , @i_line_no  , @i_who  , @i_qc_flag , @i_row_id , 
  @d_location  , @d_part_no  , @d_bin_no  , @d_lot_ser  , @d_tran_code  , @d_tran_no  , @d_tran_ext  , 
  @d_date_tran  , @d_date_expires  , @d_qty  , @d_direction  , @d_cost  , @d_uom , 
  @d_uom_qty  , @d_conv_factor  , @d_line_no  , @d_who  , @d_qc_flag , @d_row_id  
While @@FETCH_STATUS = 0
begin
  if @i_part_no != @d_part_no or @i_location != @d_location 
  begin
    rollback tran
    exec adm_raiserror 83221 ,'You cannot change a part number, location or lot/serial number on a lot_bin_recv record.'
    return
  end

  if @i_qc_flag not in ('Y','F') and @i_lot_ser != @d_lot_ser					-- mls 4/16/07 SCR 37962
  begin
    rollback tran
    exec adm_raiserror 83221, 'You cannot change lot/serial number on a lot_bin_recv record.'
    return
  end


  select @temp_qty = round((@i_uom_qty * @i_conv_factor),8)
  if @i_qty != @temp_qty
  BEGIN
    rollback tran
    exec adm_raiserror 83221, 'Inventory Qty does not relate to Unit of Measure Quantity on Updated Lot bin Recv record.'
    return
  END

  if @rcpt_no < 0 
    select @rcpt_no = @i_tran_no,
      @rcpt_qc_flag = case when @i_qc_flag != @d_qc_flag then @i_qc_flag else '' end

  if @rcpt_no != @i_tran_no
  begin
    -- update the receipt with the qty from the lot bin record updated unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty,
      qc_flag = case when @rcpt_qc_flag != '' then @rcpt_qc_flag else qc_flag end
    where receipt_no = @rcpt_no
  

    delete from lot_bin_recv
    where tran_no = @rcpt_no and qty = 0

    if @ordno is not null and @ordext is not NULL
    begin
      select @l_qty = isnull((select sum(qty) from lot_bin_ship
        where tran_no=@ordno and tran_ext=@ordext and line_no=@line_no ),0)
      update orders_auto_po set status = 'M' where po_no=@po and part_no = @i_part_no and line_no = @ord_line
      update ord_list
      set shipped = @l_qty / conv_factor
      where order_no = @ordno and order_ext = @ordext and line_no = @line_no
      update orders_auto_po set status = @oap_status where po_no=@po and part_no = @i_part_no and line_no = @ord_line
    end

    select @rcpt_qty = 0, @rcpt_no = @i_tran_no, @rcpt_qc_flag = ''
  end
  else
    select @rcpt_qty =  @rcpt_qty + @i_uom_qty - @d_uom_qty,	-- mls 9/7/06 SCR 36973
      @rcpt_qc_flag = case when @i_qc_flag != @d_qc_flag then @i_qc_flag else '' end

    select @po=r.po_no,
    @po_line = po_line,									-- mls 12/11/02 SCR 30429
    @rel_date = release_date								-- mls 12/11/02 SCR 30429
    from receipts_all r (nolock)
    where r.receipt_no = @d_tran_no

    select @ord_line = isnull((select ord_line					-- mls 12/11/02 SCR 30429 start
    from releases r (nolock)
    where r.po_no = @po and po_line = @po_line and release_date = @rel_date),NULL)

    select @ordno = NULL
    if @ord_line is not null
    begin
      select @ordno=oap.order_no, @line_no = @ord_line, @oap_status = oap.status
      from orders_auto_po oap (nolock)
      where oap.po_no=@po and oap.part_no = @d_part_no and oap.line_no = @ord_line
    end										-- mls 12/11/02 SCR 30429 end

    if isnull(@ordno,0) <> 0				
    Begin
      select @ordext=isnull((select max(ext) from orders_all (nolock) where order_no=@ordno and status < 'S'),NULL)

      if @ordext is not null
      begin	
	    UPDATE lot_bin_ship
	    SET uom_qty=uom_qty - case when qty < @d_qty then uom_qty else @d_uom_qty end,
	      qty=qty - case when qty < @d_qty then qty else @d_qty end
	    WHERE tran_no=@ordno and tran_ext=@ordext and line_no=@line_no and 
	      lot_ser= @d_lot_ser and bin_no=@d_bin_no 
      end
    END

  if @d_qc_flag != @i_qc_flag or @d_location != @i_location or @d_part_no != @i_part_no or
    @d_bin_no != @i_bin_no or @d_lot_ser != @i_lot_ser or @d_direction != @i_direction or
    @d_tran_no != @i_tran_no or @d_tran_ext != @i_tran_ext or @d_date_expires != @i_date_expires
  begin
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
        tran_no, tran_ext, date_tran, date_expires, qty, direction, 
        cost, uom, uom_qty, conv_factor, line_no, who)
      select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 
        case when @d_qc_flag = 'Y' then 'Q' else 'R' end, @d_tran_no, @d_tran_ext,	-- mls 4/23/02 SCR 28797
        @d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
        @d_conv_factor, @d_line_no, @d_who

      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
        tran_no, tran_ext, date_tran, date_expires, qty, direction, 
        cost, uom, uom_qty, conv_factor, line_no, who)
      select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 
        case when @i_qc_flag = 'Y' then 'Q' else 'R' end, @i_tran_no, @i_tran_ext,	-- mls 4/23/02 SCR 28797
        @i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
        @i_conv_factor, @i_line_no, @i_who 
  end
  else
  begin
    if @d_qty != @i_qty
    begin
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
        tran_no, tran_ext, date_tran, date_expires, qty, direction, 
        cost, uom, uom_qty, conv_factor, line_no, who)
      select @i_location, @i_part_no, @i_bin_no, @i_lot_ser,
        case when @i_qc_flag = 'Y' then 'Q' else 'R' end, @i_tran_no, @i_tran_ext,	-- mls 4/23/02 SCR 28797
        @i_date_tran, @i_date_expires, (@i_qty - @d_qty) , @i_direction, @i_cost, @i_uom, 
        (@i_uom_qty - @d_uom_qty) , @i_conv_factor, @i_line_no, @i_who 
    end
  end

    select @po=r.po_no,
    @po_line = po_line,									-- mls 12/11/02 SCR 30429
    @rel_date = release_date								-- mls 12/11/02 SCR 30429
    from receipts_all r (nolock)
    where r.receipt_no = @i_tran_no

    select @ord_line = isnull((select ord_line					-- mls 12/11/02 SCR 30429 start
    from releases r (nolock)
    where r.po_no = @po and po_line = @po_line and release_date = @rel_date),NULL)

    select @ordno = 0							
    if @ord_line is not null
    begin
      select @ordno=oap.order_no, @line_no = @ord_line, @oap_status = status
      from orders_auto_po oap (nolock)
      where oap.po_no=@po and oap.part_no = @i_part_no and oap.line_no = @ord_line
    end										-- mls 12/11/02 SCR 30429 end

    if isnull(@ordno,0) <> 0						
    begin									
      select @ordext= isnull((select max(ext) from orders_all (nolock) where order_no=@ordno and status < 'S'),NULL)

      if @ordext is not null
      begin	
      if @i_location not like 'DROP%'
      begin
        select @max_to_ship = isnull((select (ordered * conv_factor) from ord_list (nolock)
        where order_no = @ordno and order_ext = @ordext and line_no = @line_no),0)
        select @max_to_ship = @max_to_ship + isnull((select sum(qty * direction) from lot_bin_ship (nolock)
        where tran_no = @ordno and tran_ext = @ordext and line_no = @line_no),0)
        if @max_to_ship < 0   set @max_to_ship = 0

        select @l_qty = case when @max_to_ship < @i_qty then @max_to_ship  else @i_qty end
      end
      if @l_qty != 0
      begin
      if not exists (select 1 from lot_bin_ship l (nolock)
        WHERE l.tran_no=@ordno and l.tran_ext=@ordext and l.line_no=@line_no and 
          l.lot_ser=@i_lot_ser and l.bin_no=@i_bin_no)
      begin
        INSERT lot_bin_ship (qc_flag , tran_code , uom , date_expires , date_tran , uom_qty , 
          conv_factor , cost , qty , tran_no , line_no , 
          tran_ext , direction , part_no , who , bin_no , location , lot_ser ) 
        SELECT 'N' , 'Q' , @i_uom , @i_date_expires , @i_date_tran , @l_qty / @i_conv_factor , 
          @i_conv_factor , @i_cost , @l_qty , @ordno , @line_no , 
          @ordext , -1 , @i_part_no , @i_who , @i_bin_no , @i_location , @i_lot_ser 
      end
      else
      begin									
        UPDATE lot_bin_ship
        SET uom_qty=uom_qty + (@l_qty / @i_conv_factor),
	  qty=qty + @l_qty
        FROM lot_bin_ship
        WHERE tran_no=@ordno and tran_ext=@ordext and line_no=@line_no and lot_ser=@i_lot_ser and
	    bin_no=@i_bin_no 
	 
        DELETE lot_bin_ship
        WHERE tran_no=@ordno and tran_ext=@ordext and line_no=@line_no and qty=0 and uom_qty=0
      end  -- else exists							
      end -- l_qty != 0
      end -- ordext not null
    end  -- ordno <> 0							

  if @i_qc_flag = 'Y' and (@d_qty != @i_qty OR @d_lot_ser != @i_lot_ser OR @i_bin_no != @d_bin_no)
  begin
    update qc_results set qc_qty=@i_qty, lot_ser=@i_lot_ser, bin_no=@i_bin_no 
    from receipts_all r
    where r.receipt_no = @i_tran_no and qc_results.qc_no = r.qc_no
  end


  FETCH NEXT FROM updlbrecv INTO
    @i_location  , @i_part_no  , @i_bin_no  , @i_lot_ser  , @i_tran_code  , @i_tran_no  , @i_tran_ext  , 
    @i_date_tran  , @i_date_expires  , @i_qty  , @i_direction  , @i_cost  , @i_uom , 
    @i_uom_qty  , @i_conv_factor  , @i_line_no  , @i_who  , @i_qc_flag , @i_row_id , 
    @d_location  , @d_part_no  , @d_bin_no  , @d_lot_ser  , @d_tran_code  , @d_tran_no  , @d_tran_ext  , 
    @d_date_tran  , @d_date_expires  , @d_qty  , @d_direction  , @d_cost  , @d_uom , 
    @d_uom_qty  , @d_conv_factor  , @d_line_no  , @d_who  , @d_qc_flag , @d_row_id  
end -- fetchstatus = 0

  if @rcpt_no > -1
  begin
    -- update the receipt with the qty from the lot bin record updated unless user is tdcsql
    -- if tdcsql, the console app will update the receipt
    if system_user != 'tdcsql'
    update receipts_all
    set quantity = quantity + @rcpt_qty,
      qc_flag = case when @rcpt_qc_flag != '' then @rcpt_qc_flag else qc_flag end
    where receipt_no = @rcpt_no

    delete from lot_bin_recv
    where tran_no = @rcpt_no and qty = 0

    if @ordno is not null and @ordext is not NULL
    begin
      select @l_qty = isnull((select sum(qty) from lot_bin_ship
        where tran_no=@ordno and tran_ext=@ordext and line_no=@line_no ),0)
      update orders_auto_po set status = 'M' where po_no=@po and part_no = @i_part_no and line_no = @ord_line

      update ord_list
      set shipped = @l_qty / conv_factor
      where order_no = @ordno and order_ext = @ordext and line_no = @line_no
      update orders_auto_po set status = @oap_status where po_no=@po and part_no = @i_part_no and line_no = @ord_line
    end
  end
END

GO
CREATE NONCLUSTERED INDEX [lbrec2] ON [dbo].[lot_bin_recv] ([location], [part_no], [bin_no], [lot_ser], [tran_no], [line_no]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [lbrec1] ON [dbo].[lot_bin_recv] ([tran_no], [line_no], [location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_recv] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_recv] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_recv] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_recv] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_recv] TO [public]
GO
