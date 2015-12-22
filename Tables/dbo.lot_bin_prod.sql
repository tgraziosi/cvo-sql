CREATE TABLE [dbo].[lot_bin_prod]
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
[qc_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__lot_bin_p__qc_fl__11AB833E] DEFAULT ('N'),
[row_id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700dellbprod] ON [dbo].[lot_bin_prod]   FOR DELETE AS 
BEGIN

DECLARE @d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_qc_flag char(1)

declare @insert_ind int, @m_cost_method char(1), @used_qty decimal(20,8),
  @p_prod_type char(1),
  @l_tran_no int, @l_tran_ext int, @l_line_no int, @l_part_no varchar(30), @l_qty decimal(20,8),
  @l_location varchar(10)

select @l_tran_no = -999, @l_tran_ext = 0, @l_line_no = 0, @l_part_no = '', @l_qty = 0,
  @l_location = ''

DECLARE t700dellot__cursor CURSOR LOCAL STATIC FOR
SELECT d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.qc_flag, m.inv_cost_method, isnull(p.prod_type,'')
from deleted d
left outer join inv_master m (nolock) on m.part_no = d.part_no
left outer join produce_all p (nolock) on p.prod_no = d.tran_no and p.prod_ext = d.tran_ext
order by d.tran_no, d.tran_ext, d.line_no, d.part_no, d.location
OPEN t700dellot__cursor

if @@cursor_rows = 0
begin
CLOSE t700dellot__cursor
DEALLOCATE t700dellot__cursor
return
end

FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @m_cost_method, @p_prod_type

While @@FETCH_STATUS = 0
begin
  select @l_tran_no = @d_tran_no,
    @l_tran_ext = @d_tran_ext,
    @l_line_no = @d_line_no,
    @l_part_no = @d_part_no,
    @l_location = @d_location

  if isnull(@d_qc_flag,'N') != 'Y' and @d_qty != 0
  begin
    select @insert_ind = 0
    if (@d_tran_code in ('R','S')) or @d_direction < 0 or @p_prod_type = 'R'
      select @insert_ind = 1

    if @insert_ind = 1
    begin
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
      select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'P', @d_tran_no, @d_tran_ext,		-- mls 4/11/00 start
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, 
        (@d_uom_qty * -1) , @d_conv_factor, @d_line_no, @d_who 

      select @l_qty = @l_qty + @d_qty
    end
  end

FETCH NEXT FROM t700dellot__cursor into
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @m_cost_method, @p_prod_type

  if not (@l_tran_no = @d_tran_no and @l_tran_ext = @d_tran_ext and @l_line_no = @d_line_no
    and @l_part_no = @d_part_no and @l_location = @d_location) or @@FETCH_STATUS != 0
  begin
    if @l_qty != 0
    begin
      update prod_list
      set used_qty = used_qty - @l_qty,
        status = case when status < 'P' then 'P' else status end
      where prod_no = @l_tran_no and prod_ext = @l_tran_ext and
        line_no = @l_line_no and part_no = @l_part_no and location = @l_location

      select @l_qty = 0
    end
  end
end -- while

CLOSE t700dellot__cursor
DEALLOCATE t700dellot__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700inslbprod] ON [dbo].[lot_bin_prod]   FOR INSERT  AS 
BEGIN

DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),
@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,
@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,
@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),
@i_line_no int, @i_who varchar(20), @i_qc_flag char(1)

declare @insert_ind int, @m_cost_method char(1)
declare @used_qty decimal(20,8), @p_prod_type char(1)


DECLARE t700inslot__cursor CURSOR LOCAL STATIC FOR
SELECT i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,
i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,
i.line_no, i.who, i.qc_flag, m.inv_cost_method, isnull(p.prod_type,'')
from inserted i
left outer join inv_master m on m.part_no = i.part_no
left outer join produce_all p on p.prod_no = i.tran_no and p.prod_ext = i.tran_ext

OPEN t700inslot__cursor

if @@cursor_rows = 0
begin
CLOSE t700inslot__cursor
DEALLOCATE t700inslot__cursor
return
end

FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag,@m_cost_method, @p_prod_type

While @@FETCH_STATUS = 0
begin
  if @i_qty != (@i_uom_qty * @i_conv_factor)
  BEGIN
    rollback tran
    exec adm_raiserror 83221, 'Inventory Qty does not relate to Unit of Measure Quantity on Inserted Lot bin Prod record.'
    return
  END

  if (isnull(@i_qc_flag,'N') != 'Y') and @i_qty != 0
  begin
    select @insert_ind = 0
    if ((@i_tran_code in ('R','S')) or @i_direction < 0 or @p_prod_type = 'R')
      select @insert_ind = 1
 
    if @insert_ind = 1
    begin
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
      select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'P', @i_tran_no, @i_tran_ext,		-- mls 10/15/99 start
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who 

      
      if @i_direction < 0
      begin
        select @used_qty = sum(uom_qty)
        from lot_bin_prod where tran_no = @i_tran_no and tran_ext = @i_tran_ext
         and line_no = @i_line_no and part_no = @i_part_no and location = @i_location

        update prod_list
        set used_qty = @used_qty,
          status = case when status < 'P' then 'P' else status end,
		last_tran_date = isnull(@i_date_tran,last_tran_date)							-- mls 3/5/07 				
        where prod_no = @i_tran_no and prod_ext = @i_tran_ext and
          line_no = @i_line_no and part_no = @i_part_no and location = @i_location
      end
    end
  end

FETCH NEXT FROM t700inslot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @m_cost_method, @p_prod_type
end -- while

CLOSE t700inslot__cursor
DEALLOCATE t700inslot__cursor

END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE TRIGGER [dbo].[t700updlbprod] ON [dbo].[lot_bin_prod]   FOR UPDATE  AS 
BEGIN

if not (Update(location) or Update(part_no) or Update(bin_no) or Update(lot_ser) or 	-- mls 2/9/00 SCR 22323 start
Update(qty) or Update(tran_no) or Update(tran_ext) or Update(direction) or 
Update(uom_qty) or Update(conv_factor) or Update(qc_flag) or Update(tran_code))
  return

DECLARE @i_location varchar(10), @i_part_no varchar(30), @i_bin_no varchar(12),
@i_lot_ser varchar(25), @i_tran_code char(1), @i_tran_no int, @i_tran_ext int,
@i_date_tran datetime, @i_date_expires datetime, @i_qty decimal(20,8), @i_direction smallint,
@i_cost decimal(20,8), @i_uom char(2), @i_uom_qty decimal(20,8), @i_conv_factor decimal(20,8),
@i_line_no int, @i_who varchar(20), @i_qc_flag char(1), @i_row_id int,
@d_location varchar(10), @d_part_no varchar(30), @d_bin_no varchar(12),
@d_lot_ser varchar(25), @d_tran_code char(1), @d_tran_no int, @d_tran_ext int,
@d_date_tran datetime, @d_date_expires datetime, @d_qty decimal(20,8), @d_direction smallint,
@d_cost decimal(20,8), @d_uom char(2), @d_uom_qty decimal(20,8), @d_conv_factor decimal(20,8),
@d_line_no int, @d_who varchar(20), @d_qc_flag char(1), @d_row_id int, @m_cost_method char(1)

declare @cursor_rows_cnt int, @p_prod_type char(1), @dp_prod_type char(1),
  @used_qty decimal(20,8)

DECLARE t700updlot__cursor CURSOR LOCAL STATIC FOR
SELECT i.location, i.part_no, i.bin_no, i.lot_ser, i.tran_code, i.tran_no, i.tran_ext,
i.date_tran, i.date_expires, i.qty, i.direction, i.cost, i.uom, i.uom_qty, i.conv_factor,
i.line_no, i.who, i.qc_flag, i.row_id,
d.location, d.part_no, d.bin_no, d.lot_ser, d.tran_code, d.tran_no, d.tran_ext,
d.date_tran, d.date_expires, d.qty, d.direction, d.cost, d.uom, d.uom_qty, d.conv_factor,
d.line_no, d.who, d.qc_flag, d.row_id, isnull(p.prod_type,''), isnull(dp.prod_type,''),
m.inv_cost_method
from inserted i
join deleted d on i.row_id = d.row_id
left outer join produce_all p (nolock) on p.prod_no = i.tran_no and p.prod_ext = i.tran_ext
left outer join produce_all dp (nolock) on dp.prod_no = d.tran_no and dp.prod_ext = d.tran_ext
left outer join inv_master m (nolock) on m.part_no = i.part_no

OPEN t700updlot__cursor

select @cursor_rows_cnt = @@cursor_rows
if @cursor_rows_cnt = 0
begin
CLOSE t700updlot__cursor
DEALLOCATE t700updlot__cursor
return
end

FETCH NEXT FROM t700updlot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id,
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @p_prod_type, @dp_prod_type,
@m_cost_method

While @@FETCH_STATUS = 0
begin
  if @i_part_no != @d_part_no or @i_location != @d_location 
  begin
    rollback tran
    exec adm_raiserror 83221 ,'You cannot change a part number, or location on a lot_bin_prod record.'
    return
  end

  if @i_qc_flag not in ('Y','F') and @i_lot_ser != @d_lot_ser					-- mls 4/16/07 SCR 37962
  begin
    rollback tran
    exec adm_raiserror 83221 ,'You cannot change lot/serial number on a lot_bin_prod record.'
    return
  end

  if @i_qty != (@i_uom_qty * @i_conv_factor)
  BEGIN
    rollback tran
    exec adm_raiserror 83221 ,'Inventory Qty does not relate to Unit of Measure Quantity on Updated Lot bin Prod record.'
    return
  END

  
  if (isnull(@d_qc_flag,'N') != 'Y') and @d_direction < 0					-- mls 10/24/00 SCR 24720
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'P', @d_tran_no, @d_tran_ext,
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1),
	@d_conv_factor, @d_line_no, @d_who 
  end

  if (isnull(@i_qc_flag,'N') != 'Y') and @i_direction < 0					-- mls 10/24/00 SCR 24720
  begin
    insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
    select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'P', @i_tran_no, @i_tran_ext,
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who 
  end

  if (isnull(@d_qc_flag,'N') != 'Y' and @d_direction < 0) or
    (isnull(@i_qc_flag,'N') != 'Y' and @i_direction < 0	)
  begin
      select @used_qty = sum(uom_qty)
      from lot_bin_prod where tran_no = @i_tran_no and tran_ext = @i_tran_ext
       and line_no = @i_line_no and part_no = @i_part_no and location = @i_location
       and isnull(@d_qc_flag,'N') != 'Y' and (tran_code in ('R','S') or direction < 0 or @p_prod_type = 'R')

      update prod_list
      set used_qty = used_qty + (@i_qty - @d_qty),
          status = case when status < 'P' then 'P' else status end,
		last_tran_date = isnull(@i_date_tran,last_tran_date)							-- mls 3/5/07 				
      where prod_no = @i_tran_no and prod_ext = @i_tran_ext and
        line_no = @i_line_no and part_no = @i_part_no and location = @i_location
  end

  if (@cursor_rows_cnt) = 1 						-- mls 10/24/00 SCR 24720 start
  begin
    if ((isnull(@i_qc_flag,'N') != 'Y') and ((@i_tran_code in ('R','S') and @p_prod_type != 'R') or
      (@p_prod_type = 'R' and (@i_qty != @d_qty or @i_uom_qty != @d_uom_qty))) and @i_direction > 0)
    or
      ((isnull(@d_qc_flag,'N') != 'Y') and ((@d_tran_code in ('R','S') and @dp_prod_type != 'R') or
      (@dp_prod_type = 'R' and (@i_qty != @d_qty or @i_uom_qty != @d_uom_qty))) and @d_direction > 0)
    or ((isnull(@i_qc_flag,'N') != isnull(@d_qc_flag,'N'))  and (@i_tran_code in ('R','S') or	-- mls 2/26/01 SCR 26060
	@d_tran_code in ('R','S') or @p_prod_type = 'R') and @i_direction > 0)			-- mls 2/26/01 SCR 26060
    begin
      if (isnull(@i_qc_flag,'N') != 'Y') and ((@i_tran_code in ('R','S')) or			
	(@p_prod_type = 'R')) and @i_direction > 0						
        insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	  tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	  cost, uom, uom_qty, conv_factor, line_no, who)
        select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'P', @i_tran_no, @i_tran_ext,		
  	  @i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	  @i_conv_factor, @i_line_no, @i_who 

      if (isnull(@d_qc_flag,'N') != 'Y') and ((@d_tran_code in ('R','S')) or			
	(@dp_prod_type = 'R')) and @d_direction > 0						
        insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	  tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	  cost, uom, uom_qty, conv_factor, line_no, who)
        select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'P', @d_tran_no, @d_tran_ext,		
  	  @d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1) ,
	  @d_conv_factor, @d_line_no, @d_who 
    end
  end													-- mls 10/24/00 SCR 24720 end
  else
  begin
    --the negative tran has to be first because of logic in lot_bin_tran for checking serial numbers.
    if (isnull(@d_qc_flag,'N') != 'Y') and ((@d_tran_code in('R','S')) or			-- mls 10/24/00 SCR 24720
	(@dp_prod_type = 'R')) and @d_direction > 0						-- mls 10/15/99 end
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
      select @d_location, @d_part_no, @d_bin_no, @d_lot_ser, 'P', @d_tran_no, @d_tran_ext,		-- mls 10/15/99 start
	@d_date_tran, @d_date_expires, (@d_qty * -1) , @d_direction, @d_cost, @d_uom, (@d_uom_qty * -1) ,
	@d_conv_factor, @d_line_no, @d_who 

    
    if (isnull(@i_qc_flag,'N') != 'Y') and ((@i_tran_code in ('R','S')) or			-- mls 10/24/00 SCR 24720
	(@p_prod_type = 'R')) and @i_direction > 0						-- mls 10/15/99 end
      insert into lot_bin_tran (location, part_no, bin_no, lot_ser, tran_code, 
	tran_no, tran_ext, date_tran, date_expires, qty, direction, 
	cost, uom, uom_qty, conv_factor, line_no, who)
      select @i_location, @i_part_no, @i_bin_no, @i_lot_ser, 'P', @i_tran_no, @i_tran_ext,		-- mls 10/15/99 start
	@i_date_tran, @i_date_expires, @i_qty , @i_direction, @i_cost, @i_uom, @i_uom_qty ,
	@i_conv_factor, @i_line_no, @i_who 
  end



FETCH NEXT FROM t700updlot__cursor into
@i_location, @i_part_no, @i_bin_no, @i_lot_ser, @i_tran_code, @i_tran_no, @i_tran_ext,
@i_date_tran, @i_date_expires, @i_qty, @i_direction, @i_cost, @i_uom, @i_uom_qty,
@i_conv_factor, @i_line_no, @i_who, @i_qc_flag, @i_row_id,
@d_location, @d_part_no, @d_bin_no, @d_lot_ser, @d_tran_code, @d_tran_no, @d_tran_ext,
@d_date_tran, @d_date_expires, @d_qty, @d_direction, @d_cost, @d_uom, @d_uom_qty,
@d_conv_factor, @d_line_no, @d_who, @d_qc_flag, @d_row_id, @p_prod_type, @dp_prod_type,
@m_cost_method
end -- while

CLOSE t700updlot__cursor
DEALLOCATE t700updlot__cursor

END
GO
CREATE NONCLUSTERED INDEX [lbprod2] ON [dbo].[lot_bin_prod] ([location], [part_no], [bin_no], [lot_ser], [tran_no], [tran_ext], [line_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [lot_bin_prod_row_id] ON [dbo].[lot_bin_prod] ([row_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [lbprod1] ON [dbo].[lot_bin_prod] ([tran_no], [tran_ext], [line_no], [location], [part_no], [bin_no], [lot_ser]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[lot_bin_prod] TO [public]
GO
GRANT SELECT ON  [dbo].[lot_bin_prod] TO [public]
GO
GRANT INSERT ON  [dbo].[lot_bin_prod] TO [public]
GO
GRANT DELETE ON  [dbo].[lot_bin_prod] TO [public]
GO
GRANT UPDATE ON  [dbo].[lot_bin_prod] TO [public]
GO
