CREATE TABLE [dbo].[releases]
(
[timestamp] [timestamp] NOT NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_date] [datetime] NOT NULL,
[quantity] [decimal] (20, 8) NOT NULL,
[received] [decimal] (20, 8) NOT NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[confirm_date] [datetime] NULL,
[confirmed] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lb_tracking] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[conv_factor] [decimal] (20, 8) NOT NULL,
[prev_qty] [decimal] (20, 8) NULL,
[po_key] [int] NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[due_date] [datetime] NULL,
[ord_line] [int] NULL,
[po_line] [int] NULL CONSTRAINT [DF__releases__po_lin__379C21FC] DEFAULT ((0)),
[receipt_batch_no] [int] NULL,
[int_order_no] [int] NULL,
[int_ord_line] [int] NULL,
[departure_date] [datetime] NULL,
[inhouse_date] [datetime] NULL,
[over_ride] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600delrel] ON [dbo].[releases]   FOR DELETE AS 
BEGIN

if exists (select * from config where flag='TRIG_DEL_REL' and value_str='DISABLE') return

declare @ordext int, @ordno int, @line_no int, @retval int
declare @prodno int, @prodext int, @prodlin int

declare
@d_po_no varchar (16)  ,
@d_part_no varchar (30)  ,
@d_location varchar (10)  ,
@d_part_type varchar (10)  ,
@d_release_date datetime  ,
@d_quantity decimal(20, 8)  ,
@d_received decimal(20, 8)  ,
@d_status char (1)  ,
@d_confirm_date datetime  ,
@d_confirmed char (1)  ,
@d_lb_tracking char (1)  ,
@d_conv_factor decimal(20, 8)  ,
@d_prev_qty decimal(20, 8)  ,
@d_po_key int  ,
@d_row_id int ,
@d_due_date datetime  ,
@d_ord_line int  ,
@d_po_line int

declare @last_po varchar(16), @last_part varchar(30), @last_line int
declare @rqty decimal(20,8), @who varchar(20), @pl_type char(1), @po_status char(1), @po_blanket char(1),
  @po_approval_status char(1)

declare @o_back_ord_flag char(1)					-- mls 9/24/01 SCR 27636
declare @o_create_po_flag int						-- dpardo REV 6

DECLARE reldel CURSOR LOCAL FOR
SELECT po_no, part_no, location, part_type, release_date, quantity, received, status,
confirm_date, confirmed, lb_tracking, conv_factor, prev_qty, po_key, row_id, due_date, 
ord_line, po_line 
FROM deleted
order by po_no, part_no, po_line

select @last_po = '', @last_part = '', @last_line = -1

OPEN reldel
FETCH NEXT FROM reldel INTO
@d_po_no, @d_part_no, @d_location, @d_part_type, @d_release_date, @d_quantity, 
@d_received, @d_status, @d_confirm_date, @d_confirmed, @d_lb_tracking, @d_conv_factor, 
@d_prev_qty, @d_po_key, @d_row_id, @d_due_date, @d_ord_line, @d_po_line 

While @@FETCH_STATUS = 0
begin
    if not (@last_po = @d_po_no and @last_part = @d_part_no and @last_line = @d_po_line)
    begin
      select @who = who_entered, @pl_type = type
      from pur_list (nolock)
      WHERE  po_no=@d_po_no and part_no= @d_part_no and 
	line = case when isnull(@d_po_line,0)=0 then line else @d_po_line end

      select @po_status = status, @po_blanket = blanket,
        @po_approval_status = isnull(approval_status,'')				-- mls 7/17/03 SCR 31491
      from purchase_all (nolock) where po_no = @d_po_no

      if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
      begin	
        rollback tran
        exec adm_raiserror 81139, 'This purchase order is being processed by eProcurement.  It cannot be changed.'
        return
      end

      update pur_list set 
        qty_ordered = isnull((select sum(r.quantity) from releases r
	  where r.po_no = @d_po_no and r.part_no = @d_part_no and
	    r.po_line = @d_po_line),0),
	qty_received = isnull((select sum(r.received) from releases r
          where r.po_no = @d_po_no and r.part_no = @d_part_no and
	    r.po_line = @d_po_line),0),
        status= case when @po_blanket != 'Y' and @po_status != 'H' then
          isnull((select min(status) from releases r
          where r.po_no = @d_po_no and r.po_line = @d_po_line and r.part_no = @d_part_no 
            and r.status='O'),'C') 
          else status end
	where (po_no = @d_po_no) and (part_no = @d_part_no)
        and (line = case when isnull(@d_po_line,0)=0 then line else @d_po_line end) 

      select @last_po = @d_po_no, @last_part = @d_part_no, @last_line = @d_po_line
    end

  if @d_received > 0
  begin
    rollback tran
    exec adm_raiserror 71231, 'You Can Not Delete A Received Item!'
    return
  end

 
--  begin
    if exists (select 1 from orders_auto_po oap (nolock)
      where oap.po_no= @d_po_no and oap.part_no= @d_part_no and 
	oap.line_no = isnull(@d_ord_line,-1) and					-- mls 5/9/01 #2
	oap.status='P')								-- mls 3/29/02 SCR 28599
    begin
      
      select @ordno=oap.order_no, @line_no=oap.line_no
      from orders_auto_po oap (nolock)
      where oap.po_no=@d_po_no and oap.part_no=@d_part_no 
        and oap.line_no = isnull(@d_ord_line,-1)					-- mls 5/9/01 #2

      select @ordext=(select max(ext) from orders_all (nolock) where order_no=@ordno)
  
      if @d_location not like 'DROP%'								-- mls 3/19/03 SCR 30862
      begin
        select @o_create_po_flag = create_po_flag 
        from ord_list (nolock)
        where order_no = @ordno and line_no = @line_no and part_no = @d_part_no
          and order_ext = @ordext
      end

      if @d_location like 'DROP%' or ( isnull(@o_create_po_flag,0) = 1) 				-- mls 3/19/03 SCR 30862
      begin
        select @o_back_ord_flag = isnull((select back_ord_flag from orders_all (nolock)		-- mls 9/24/01 SCR 27636
       	where order_no = @ordno and ext = @ordext),'0')					

        update orders_auto_po 
        set status='N',
          po_no = NULL										-- mls 3/19/03 SCR 30862
        where po_no=@d_po_no and part_no=@d_part_no and status='P' and				-- mls 3/29/02 SCR 28599
          line_no = isnull(@d_ord_line,-1) 
		
        update oap										-- mls 4/16/02 SCR 28599 start
        set qty = o.ordered
	from orders_auto_po oap, ord_list o
	where o.order_no = @ordno and o.order_ext = @ordext and o.order_no = oap.order_no and
	  oap.part_no = @d_part_no and oap.line_no = o.line_no and o.line_no = @line_no 		-- mls 4/16/02 SCR 28599 end

        update ord_list 
	set shipped=0 ,	--ordered = 0								-- mls 3/29/02 SCR 28599
	  note='Deleted Auto PO Release Original Order Qty='+convert(varchar(22),@d_quantity)+'  On '+convert(varchar(8),getdate(),1)
	where order_ext = @ordext and order_no=@ordno and line_no=@line_no and status <='R'
      end
    end			

    if 	(@d_quantity - @d_received) > 0 and @d_status='O' and @d_part_type != 'M'		-- mls 7/16/01 SCR 26824
  begin
    update inv_recv 
    set po_on_order=po_on_order - ((@d_quantity - @d_received) * @d_conv_factor)
    where part_no=@d_part_no and location=@d_location 
  end

  

  if @po_status = 'O' and @pl_type = 'P' 
  begin
    if exists ( select 1 from agents WHERE part_no = @d_part_no and agent_type = 'B' )
    begin
  
      SELECT  @rqty = @d_quantity * @d_conv_factor
      select @rqty = -1 * @rqty
      exec @retval=fs_agent @d_part_no, 'B', @d_po_key, @d_release_date, @who, @rqty
      if @retval= -3 
      begin
        rollback tran
        exec adm_raiserror 71234 ,'Agent Error... Outsource item not found on this Prod No!'
        return
      end
      if @retval<=0 
      begin
        rollback tran
        exec adm_raiserror 71235, 'Agent Error... Try Re-Saving!'
        return
      end
    end
  end
   

  FETCH NEXT FROM reldel into
  @d_po_no, @d_part_no, @d_location, @d_part_type, @d_release_date, @d_quantity, 
  @d_received, @d_status, @d_confirm_date, @d_confirmed, @d_lb_tracking, @d_conv_factor, 
  @d_prev_qty, @d_po_key, @d_row_id, @d_due_date, @d_ord_line, @d_po_line 
end 


CLOSE reldel
DEALLOCATE reldel
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t600insrel] ON [dbo].[releases]   FOR INSERT  AS 
BEGIN
if exists (select * from config where flag='TRIG_INS_REL' and value_str='DISABLE') return

declare
@i_po_no varchar (16)  ,
@i_part_no varchar (30)  ,
@i_location varchar (10)  ,
@i_part_type varchar (10)  ,
@i_release_date datetime  ,
@i_quantity decimal(20, 8)  ,
@i_received decimal(20, 8)  ,
@i_status char (1)  ,
@i_confirm_date datetime  ,
@i_confirmed char (1)  ,
@i_lb_tracking char (1)  ,
@i_conv_factor decimal(20, 8)  ,
@i_prev_qty decimal(20, 8)  ,
@i_po_key int  ,
@i_row_id int ,
@i_due_date datetime  ,
@i_ord_line int  ,
@i_po_line int

declare @retval int
declare @last_po varchar(16), @last_part varchar(30), @last_line int
declare @rqty decimal(20,8), @who varchar(20), @pl_type char(1), @po_status char(1), @po_blanket char(1),
  @po_approval_status char(1)


DECLARE relins CURSOR LOCAL FOR
SELECT po_no, part_no, location, part_type, release_date, quantity, received, status,
confirm_date, confirmed, lb_tracking, conv_factor, prev_qty, po_key, row_id, due_date, 
ord_line, po_line 
FROM inserted
order by po_no, part_no, po_line

select @last_po = '', @last_part = '', @last_line = -1

OPEN relins
FETCH NEXT FROM relins INTO
@i_po_no, @i_part_no, @i_location, @i_part_type, @i_release_date, @i_quantity, 
@i_received, @i_status, @i_confirm_date, @i_confirmed, @i_lb_tracking, @i_conv_factor, 
@i_prev_qty, @i_po_key, @i_row_id, @i_due_date, @i_ord_line, @i_po_line 

While @@FETCH_STATUS = 0
begin

  if @i_status='C'
  begin
    rollback tran
    exec adm_raiserror 81231, 'You Can Not Inserted A Closed Item!'
    return
  end

  if not (@last_po = @i_po_no and @last_part = @i_part_no and @last_line = @i_po_line)
  begin
    select @who = who_entered, @pl_type = type
    from pur_list (nolock)
    WHERE  po_no=@i_po_no and part_no= @i_part_no and 
      line = case when isnull(@i_po_line,0)=0 then line else @i_po_line end

    IF @@ROWCOUNT = 0
    BEGIN
      rollback tran	
      exec adm_raiserror 81201 ,'Purchase List Item Missing. The transaction is being rolled back.'
      RETURN
    END

    if @last_po != @i_po_no
    begin
      select @po_status = status, @po_blanket = blanket,
        @po_approval_status = isnull(approval_status,'')			-- mls 7/17/03 SCR 31491
      from purchase_all (nolock) where po_no = @i_po_no

      IF @po_status not in ('O','H')
      BEGIN
        rollback tran	
        exec adm_raiserror 81235, 'Purchase Order Closed....Cannot Add Items!'
        RETURN
      END

      if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
      begin	
        rollback tran
        exec adm_raiserror 81139, 'This purchase order is being processed by eProcurement.  It cannot be changed.'
        return
      end
    end

    update pur_list set 
      qty_ordered = isnull((select sum(r.quantity) from releases r
        where r.po_no = @i_po_no and r.part_no = @i_part_no and
          r.po_line = @i_po_line),0),
      qty_received = isnull((select sum(r.received) from releases r
        where r.po_no = @i_po_no and r.part_no = @i_part_no and
          r.po_line = @i_po_line),0),
      status= case when @po_blanket != 'Y' and @po_status != 'H' then
        isnull((select min(status) from releases r
        where r.po_no = @i_po_no and r.po_line = @i_po_line and r.part_no = @i_part_no 
          and r.status='O'),'C') 
        else status end
    where (po_no = @i_po_no) and (part_no = @i_part_no) 
      and (line = case when isnull(@i_po_line,0)=0 then line else @i_po_line end) 

    select @last_po = @i_po_no, @last_part = @i_part_no, @last_line = @i_po_line
  end
 

  if @i_location like 'DROP%'
  begin
    if not exists (select 1 from orders_auto_po oap (nolock) 
      where oap.po_no=@i_po_no and oap.part_no=@i_part_no and oap.status='O')
    begin
      rollback tran
      exec adm_raiserror 81233, 'You Can Not Add Items To A DROP Shipment - See Customer Service!'
      return
    end			
  end

  if (@i_quantity - @i_received) > 0 and @i_part_type != 'M' and				-- mls 2/26/01 SCR 25824
    @i_status='O' 
  begin
    update inv_recv 
    set po_on_order=po_on_order + ((@i_quantity - @i_received) * @i_conv_factor)
    where part_no=@i_part_no and location = @i_location 
  end

   

  if @po_status = 'O' and @pl_type = 'P' 
  begin
    if exists ( select 1 from agents (nolock) WHERE part_no = @i_part_no and agent_type = 'B' )
    begin
      SELECT @rqty = @i_quantity * @i_conv_factor
      exec @retval=fs_agent @i_part_no, 'B', @i_po_key, @i_release_date, @who, @rqty
      if @retval= -3 
      begin
        rollback tran
        exec adm_raiserror 81234 ,'Agent Error... Outsource item not found on this Prod No!'
        return
      end
      if @retval<=0 
      begin
        rollback tran
        exec adm_raiserror 81235 ,'Agent Error... Try Re-Saving!'
        return
      end
    end
  end
   

  FETCH NEXT FROM relins into
  @i_po_no, @i_part_no, @i_location, @i_part_type, @i_release_date, @i_quantity, 
  @i_received, @i_status, @i_confirm_date, @i_confirmed, @i_lb_tracking, @i_conv_factor, 
  @i_prev_qty, @i_po_key, @i_row_id, @i_due_date, @i_ord_line, @i_po_line 
end 


CLOSE relins
DEALLOCATE relins
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




CREATE TRIGGER [dbo].[t600updrel] ON [dbo].[releases]   FOR UPDATE  AS 
-- Audits created by ELabarbera 11/11/13
-- confirm_date_line
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'confirm_date_line' AS field_name, d.confirm_date, i.confirm_date, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and i.confirm_date<>d.confirm_date
-- over_ride
INSERT CVO_PO_AUDIT (field_name, field_from, field_to, po_no, po_line, part_no, modified_date, modified_by)
	SELECT 'over_ride' AS field_name, d.over_ride, i.over_ride, i.po_no, '', '', getdate(), SUSER_SNAME()
		from inserted i, deleted d
		where i.row_id = d.row_id
		and i.over_ride<>d.over_ride



BEGIN
declare @rc int, @msg varchar(255)

if exists (select * from config where flag='TRIG_UPD_REL' and value_str='DISABLE') return

declare
@i_po_no varchar (16)  ,
@i_part_no varchar (30)  ,
@i_location varchar (10)  ,
@i_part_type varchar (10)  ,
@i_release_date datetime  ,
@i_quantity decimal(20, 8)  ,
@i_received decimal(20, 8)  ,
@i_status char (1)  ,
@i_confirm_date datetime  ,
@i_confirmed char (1)  ,
@i_lb_tracking char (1)  ,
@i_conv_factor decimal(20, 8)  ,
@i_prev_qty decimal(20, 8)  ,
@i_po_key int  ,
@i_row_id int ,
@i_due_date datetime  ,
@i_ord_line int  ,
@i_po_line int
declare
@d_po_no varchar (16)  ,
@d_part_no varchar (30)  ,
@d_location varchar (10)  ,
@d_part_type varchar (10)  ,
@d_release_date datetime  ,
@d_quantity decimal(20, 8)  ,
@d_received decimal(20, 8)  ,
@d_status char (1)  ,
@d_confirm_date datetime  ,
@d_confirmed char (1)  ,
@d_lb_tracking char (1)  ,
@d_conv_factor decimal(20, 8)  ,
@d_prev_qty decimal(20, 8)  ,
@d_po_key int  ,
@d_row_id int ,
@d_due_date datetime  ,
@d_ord_line int  ,
@d_po_line int

declare @retval int, @pl_chg int
declare @last_po varchar(16), @last_part varchar(30), @last_line int
declare @rqty decimal(20,8), @who varchar(20), @pl_type char(1), @po_status char(1), @po_blanket char(1)
declare @rqty2 decimal(20,8),
  @po_approval_status char(1)

DECLARE @o_back_ord_flag char(1)
declare @o_status char(1)

declare @create_po_flag int			

DECLARE relupd CURSOR LOCAL FOR
SELECT i.po_no, i.part_no, i.location, i.part_type, i.release_date, i.quantity, i.received, i.status,
i.confirm_date, i.confirmed, i.lb_tracking, i.conv_factor, i.prev_qty, i.po_key, i.row_id, i.due_date, 
i.ord_line, i.po_line,
d.po_no, d.part_no, d.location, d.part_type, d.release_date, d.quantity, d.received, d.status,
d.confirm_date, d.confirmed, d.lb_tracking, d.conv_factor, d.prev_qty, d.po_key, d.row_id, d.due_date, 
d.ord_line, d.po_line 
FROM inserted i, deleted d
where i.row_id = d.row_id
order by i.po_no, i.part_no, i.po_line

select @last_po = '', @last_part = '', @pl_chg = 0, @last_line = -1

OPEN relupd
FETCH NEXT FROM relupd INTO
@i_po_no, @i_part_no, @i_location, @i_part_type, @i_release_date, @i_quantity, 
@i_received, @i_status, @i_confirm_date, @i_confirmed, @i_lb_tracking, @i_conv_factor, 
@i_prev_qty, @i_po_key, @i_row_id, @i_due_date, @i_ord_line, @i_po_line, 
@d_po_no, @d_part_no, @d_location, @d_part_type, @d_release_date, @d_quantity, 
@d_received, @d_status, @d_confirm_date, @d_confirmed, @d_lb_tracking, @d_conv_factor, 
@d_prev_qty, @d_po_key, @d_row_id, @d_due_date, @d_ord_line, @d_po_line 

While @@FETCH_STATUS = 0
begin

  if @i_release_date != @d_release_date and @i_status = 'C'
  begin	
    rollback tran
    exec adm_raiserror 91231, 'You Can Not Change Release Date Of A Closed Item!'
    return
  end

  if @i_po_no != @d_po_no
  begin	
    rollback tran
    exec adm_raiserror 91231,'You Can Not Change the PO Number of a Release!'
    return
  end
  if @i_part_no != @d_part_no
  begin	
    rollback tran
    exec adm_raiserror 91231, 'You Can Not Change the Part Number on a Release!'
    return
  end
  if @i_po_line != @d_po_line and @d_po_line != 0
  begin	
    rollback tran
    exec adm_raiserror 91231 ,'You Can Not Change the Line Number on a Release!'
    return
  end

  if @d_location like 'DROP%' and @i_location not like 'DROP%'				-- mls 3/29/02 SCR 28599 start
  begin
    rollback tran
    exec adm_raiserror 91232 ,'You Can Not Change a DROP PO release to a non drop location'
    return
  end											-- mls 3/29/02 SCR 28599 end

  if not (@last_po = @i_po_no and @last_part = @i_part_no and @last_line = @i_po_line)
  begin
    if (@last_po != @i_po_no or @last_part != @i_part_no or @last_line != @i_po_line) 		-- mls #16
      and @last_po != '' and @pl_chg = 1
    begin
      update pur_list 
      set qty_ordered = isnull((select sum(r.quantity) from releases r
          where r.po_no = @last_po and r.po_line = @last_line and r.part_no = @last_part),0), -- mls #16
        qty_received = isnull((select sum(r.received) from releases r
          where r.po_no = @last_po and r.po_line = @last_line and r.part_no = @last_part),0), -- mls #16
        status= case when @po_blanket != 'Y' and @po_status != 'H' then
          isnull((select min(status) from releases r	
          where r.po_no = @last_po and r.po_line = @last_line 					-- mls #16
            and r.part_no = @last_part and r.status='O'),'C') 
          else status end
      where (po_no = @last_po) and (part_no = @last_part) and 
	(line = case when isnull(@last_line,0)=0 then line else @last_line end)			-- mls #16
    end

    select @who = who_entered,
      @pl_type = type
    from pur_list (nolock)
    WHERE  po_no=@i_po_no and part_no= @i_part_no and 
	line = case when isnull(@i_po_line,0)=0 then line else @i_po_line end			-- mls #16

    if @@ROWCOUNT = 0
    BEGIN
      rollback tran	
      exec adm_raiserror 81201 ,'Purchase List Item Missing. The transaction is being rolled back.'
      RETURN
    END

    if @last_po != @i_po_no
    begin
      select @po_status = status, 
        @po_blanket = blanket,
        @po_approval_status = isnull(approval_status,'')				-- mls 7/17/03 SCR 31491
      from purchase_all (nolock) where po_no = @i_po_no

      if @@ROWCOUNT = 0
      BEGIN
        rollback tran	
        exec adm_raiserror 81202, 'Purchase Header Missing. The transaction is being rolled back.'
        RETURN
      END

      if @po_approval_status = 'P' 							-- mls 7/17/03 SCR 31491
      begin	
        rollback tran
        exec adm_raiserror 81139 ,'This purchase order is being processed by eProcurement.  It cannot be changed.'
        return
      end
    end

    select @last_po = @i_po_no, @last_part = @i_part_no, @pl_chg = 0, @last_line = @i_po_line	-- mls #16
  end

  if (@i_quantity != @d_quantity) or (@i_received != @d_received) or
    (@i_status != @d_status) or (@i_status = 'C' and update(status))	-- mls 12/11/02 SCR 29176
    select @pl_chg = 1

  if  (@i_quantity != @d_quantity or @i_received != @d_received or @i_status != @d_status or @i_status = 'C')
  begin
    exec @rc = adm_po_sales_order_update @i_po_no, @i_part_no, @i_release_date, @i_po_line, @d_quantity,
      @d_received, @d_status, @msg out

    if @rc < 1
    begin    
      select @msg = '(' + convert(varchar(10), @rc) + ') ' + @msg
      rollback tran
      exec adm_raiserror 91232, @msg
      return
    end
  end

  if @i_release_date != @d_release_date
  BEGIN
    
    update receipts_all 
    set release_date= @i_release_date
    where @i_po_no = po_no and @d_release_date = release_date and @i_part_no = part_no
  END

  if (( @i_status = 'O' and @i_part_type != 'M' and (@i_quantity - @i_received) != 0) or
    (@d_status = 'O' and @d_part_type != 'M' and (@d_quantity - @d_received) != 0)) and
    (@i_quantity != @d_quantity or @i_received != @d_received or @i_part_type != @d_part_type or
    @i_location != @d_location or @i_status != @d_status or @i_conv_factor != @d_conv_factor)
  begin
    if @i_location = @d_location
    begin
      update inv_recv 
      set po_on_order=po_on_order + 
        case when @i_status = 'O' and @i_part_type != 'M' and (@i_quantity - @i_received) > 0
          then ((@i_quantity - @i_received) * @i_conv_factor) else 0 end -
        case when @d_status = 'O' and @d_part_type != 'M' and (@d_quantity - @d_received) > 0
          then ((@d_quantity - @d_received) * @d_conv_factor) else 0 end
      where part_no=@i_part_no and @i_location=location 
    end
    else
    begin
      if @i_status = 'O' and @i_quantity - @i_received > 0 and @i_part_type != 'M'		-- mls 2/26/01 SCR 25824
      begin
        update inv_recv 
        set po_on_order=po_on_order + ((@i_quantity - @i_received) * @i_conv_factor)
        where part_no=@i_part_no and @i_location=location 
      end
      if @d_status = 'O' and @d_quantity - @d_received > 0 and @d_part_type != 'M'		-- mls 2/26/01 SCR 25824
      begin
        update inv_recv 
        set po_on_order=po_on_order - ((@d_quantity - @d_received) * @d_conv_factor)
        where part_no=@d_part_no and @d_location=location 
      end
    end
  end

  
  select @rqty = @i_quantity * @i_conv_factor,
    @rqty2 = @d_quantity * @d_conv_factor

  SELECT @rqty = @rqty - @rqty2

  if @po_status = 'O' and @pl_type = 'P' and @rqty != 0 
  begin
    if exists ( select 1 from agents (nolock) WHERE part_no = @i_part_no and agent_type = 'B' )
    begin
      exec @retval = fs_agent @i_part_no, 'B', @i_po_key, @i_release_date, @who, @rqty
  
      if @retval= -3 
      begin
        rollback tran
        exec adm_raiserror 91234, 'Agent Error... Outsource item not found on this Prod No!'
        return
      end
 
      if @retval<=0 
      begin
        rollback tran
        exec adm_raiserror 91235, 'Agent Error... Try Re-Saving!'
        return
      end
    end
  end
  
 
  FETCH NEXT FROM relupd into
  @i_po_no, @i_part_no, @i_location, @i_part_type, @i_release_date, @i_quantity, 
  @i_received, @i_status, @i_confirm_date, @i_confirmed, @i_lb_tracking, @i_conv_factor, 
  @i_prev_qty, @i_po_key, @i_row_id, @i_due_date, @i_ord_line, @i_po_line,
  @d_po_no, @d_part_no, @d_location, @d_part_type, @d_release_date, @d_quantity, 
  @d_received, @d_status, @d_confirm_date, @d_confirmed, @d_lb_tracking, @d_conv_factor, 
  @d_prev_qty, @d_po_key, @d_row_id, @d_due_date, @d_ord_line, @d_po_line 
end 

if  @last_po != '' and @pl_chg = 1
begin
  update pur_list 
  set qty_ordered = isnull((select sum(r.quantity) from releases r
      where r.po_no = @last_po and r.po_line = @last_line and r.part_no = @last_part),0),	-- mls #16
    qty_received = isnull((select sum(r.received) from releases r
      where r.po_no = @last_po and r.po_line = @last_line and r.part_no = @last_part),0),	-- mls #16
    status= case when @po_blanket != 'Y' and @po_status != 'H' then
      isnull((select min(status) from releases r
      where r.po_no = @last_po and r.po_line = @last_line and r.part_no = @last_part 		-- mls #16
        and r.status='O'),'C') 
      else status end
  where (po_no = @last_po) and (part_no = @last_part) and 
	(line = case when isnull(@last_line,0)=0 then line else @last_line end)
end

CLOSE relupd
DEALLOCATE relupd

END


GO
CREATE NONCLUSTERED INDEX [releasesm1] ON [dbo].[releases] ([location], [status], [part_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [releases_idx1_101613] ON [dbo].[releases] ([part_no], [location], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [relkey] ON [dbo].[releases] ([po_key], [po_line], [part_no], [release_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [rel1] ON [dbo].[releases] ([po_no], [po_line], [part_no], [release_date]) ON [PRIMARY]
GO
CREATE STATISTICS [_dta_stat_916979139_4_9_3_2_19] ON [dbo].[releases] ([location], [status], [part_no], [po_no], [po_line])
GO
CREATE STATISTICS [_dta_stat_916979139_3_2] ON [dbo].[releases] ([part_no], [po_no])
GO
CREATE STATISTICS [_dta_stat_916979139_2_19_3_6_4_9] ON [dbo].[releases] ([po_no], [po_line], [part_no], [release_date], [location], [status])
GO
GRANT REFERENCES ON  [dbo].[releases] TO [public]
GO
GRANT SELECT ON  [dbo].[releases] TO [public]
GO
GRANT INSERT ON  [dbo].[releases] TO [public]
GO
GRANT DELETE ON  [dbo].[releases] TO [public]
GO
GRANT UPDATE ON  [dbo].[releases] TO [public]
GO
