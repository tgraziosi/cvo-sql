CREATE TABLE [dbo].[load_list]
(
[timestamp] [timestamp] NOT NULL,
[load_no] [int] NOT NULL,
[seq_no] [int] NOT NULL,
[order_no] [int] NOT NULL,
[order_ext] [int] NOT NULL,
[order_list_row_id] [int] NOT NULL,
[freight] [money] NOT NULL,
[date_shipped] [datetime] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730delloadl] ON [dbo].[load_list] FOR DELETE AS 
BEGIN
DECLARE @d_load_no int, @d_seq_no int, @d_order_no int, @d_order_ext int,
@d_order_list_row_id int, @d_freight decimal(20,8), @d_date_shipped datetime

DECLARE @load_master_status char(1)

DECLARE loadldel CURSOR LOCAL FOR
SELECT 
d.load_no, d.seq_no, d.order_no, d.order_ext, d.order_list_row_id, d.freight, d.date_shipped
from deleted d
order by d.load_no, d.seq_no

OPEN loadldel
FETCH NEXT FROM loadldel INTO
@d_load_no, @d_seq_no, @d_order_no, @d_order_ext, @d_order_list_row_id, @d_freight, @d_date_shipped

While @@FETCH_STATUS = 0
begin    
  select @load_master_status = isnull((select status
    from load_master_all where load_no = @d_load_no),'X')

  if @load_master_status = 'C' 
  begin
    rollback tran
    exec adm_raiserror 2002210, 'You cannot update a shipment in credit hold status!'
    return
  end
  if @load_master_status between 'R' and 'T'
  begin
    rollback tran
    exec adm_raiserror 2002211, 'You cannot delete from a shipment in shipped status!'
    return
  end

  update orders_all
  set load_no = 0
  where order_no = @d_order_no and ext = @d_order_ext and load_no != 0

  FETCH NEXT FROM loadldel INTO
  @d_load_no, @d_seq_no, @d_order_no, @d_order_ext, @d_order_list_row_id, @d_freight, @d_date_shipped
end -- while

close loadldel
deallocate loadldel
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730insloadl] ON [dbo].[load_list] FOR INSERT AS 
BEGIN
DECLARE @i_load_no int, @i_seq_no int, @i_order_no int, @i_order_ext int,
@i_order_list_row_id int, @i_freight decimal(20,8), @i_date_shipped datetime

DECLARE @load_master_status char(1)
DECLARE @orders_status char(1), @orders_load_no int

DECLARE loadlins CURSOR LOCAL FOR
SELECT 
i.load_no, i.seq_no, i.order_no, i.order_ext, i.order_list_row_id, i.freight, i.date_shipped
from inserted i
order by i.load_no, i.seq_no

OPEN loadlins
FETCH NEXT FROM loadlins INTO
@i_load_no, @i_seq_no, @i_order_no, @i_order_ext, @i_order_list_row_id, @i_freight, @i_date_shipped

While @@FETCH_STATUS = 0
begin
  select @load_master_status = isnull((select status
    from load_master_all where load_no = @i_load_no),'X')

  if @load_master_status = 'C' 
  begin
    rollback tran
    exec adm_raiserror 2002010, 'You cannot update a shipment in credit hold status!'
    return
  end
  if @load_master_status between 'R' and 'T'
  begin
    rollback tran
    exec adm_raiserror 2002011, 'You cannot add to a shipment in shipped status!'
    return
  end
  if @load_master_status = 'V' 
  begin
    rollback tran
    exec adm_raiserror 2002012, 'You cannot add to a voided shipment!'
    return
  end

  select @orders_status = status, @orders_load_no = load_no
  from orders_all (nolock) where order_no = @i_order_no and ext = @i_order_ext

  if @@ROWCOUNT = 0
  begin
    rollback tran
    exec adm_raiserror 2002001, 'No corresponding order found on orders table!'
    return
  end

  if @orders_status < 'M'
  begin
    rollback tran
    exec adm_raiserror 2002002, 'An order in hold cannot be placed on a shipment'
    return
  end
 
  if @orders_status = 'M'
  begin
    rollback tran
    exec adm_raiserror 2002003, 'A blanket order header cannot be placed on a shipment'
    return
  end

  if isnull(@orders_load_no,0) != @i_load_no and isnull(@orders_load_no,0) != 0
  begin
    rollback tran
    exec adm_raiserror 2002006,'An order on another shipment cannot be added to this shipment'
    return
  end

  if @orders_status between 'R' and 'T'
  begin
    rollback tran
    exec adm_raiserror 2002004, 'A shipped order cannot be placed on a shipment'
    return
  end

  if @orders_status > 'T'
  begin
    rollback tran
    exec adm_raiserror 2002005, 'A voided order cannot be placed on a shipment'
    return
  end

  update orders_all
  set date_shipped = @i_date_shipped,
    load_no = @i_load_no
  where order_no = @i_order_no and ext = @i_order_ext and
    isnull(load_no,0) != @i_load_no

  FETCH NEXT FROM loadlins INTO
  @i_load_no, @i_seq_no, @i_order_no, @i_order_ext, @i_order_list_row_id, @i_freight, @i_date_shipped
end -- while

close loadlins
deallocate loadlins
END

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t730updloadl] ON [dbo].[load_list] FOR UPDATE AS 
BEGIN

if update( order_no ) or update( order_ext ) begin
	rollback tran
	exec adm_raiserror 95731, 'You Can Not Change Order No! Delete Line Then Insert New Line With Correct Order No!'
	return
end

DECLARE @i_load_no int, @i_seq_no int, @i_order_no int, @i_order_ext int,
@i_order_list_row_id int, @i_freight decimal(20,8), @i_date_shipped datetime
DECLARE @d_load_no int, @d_seq_no int, @d_order_no int, @d_order_ext int,
@d_order_list_row_id int, @d_freight decimal(20,8), @d_date_shipped datetime

DECLARE @load_master_status char(1)

DECLARE loadlupd CURSOR LOCAL FOR
SELECT 
i.load_no, i.seq_no, i.order_no, i.order_ext, i.order_list_row_id, i.freight, i.date_shipped,
d.load_no, d.seq_no, d.order_no, d.order_ext, d.order_list_row_id, d.freight, d.date_shipped
from inserted i
left outer join deleted d on i.load_no = d.load_no and i.order_no = d.order_no and i.order_ext = d.order_ext
order by i.load_no, i.seq_no

OPEN loadlupd
FETCH NEXT FROM loadlupd INTO
@i_load_no, @i_seq_no, @i_order_no, @i_order_ext, @i_order_list_row_id, @i_freight, @i_date_shipped,
@d_load_no, @d_seq_no, @d_order_no, @d_order_ext, @d_order_list_row_id, @d_freight, @d_date_shipped

While @@FETCH_STATUS = 0
begin
  if @d_load_no is NULL
  begin
    rollback tran
    exec adm_raiserror 2002101, 'You Can NOT Change The shipment number of a shipment line!'
    return
  end

  select @load_master_status = isnull((select status
    from load_master_all where load_no = @i_load_no),'X')

  if @load_master_status = 'C' 
  begin
    rollback tran
    exec adm_raiserror 2002110, 'You cannot update a shipment in credit hold status!'
    return
  end
  if @load_master_status between 'R' and 'T'
  begin
    rollback tran
    exec adm_raiserror 2002111, 'You cannot update a shipment in shipped status!'
    return
  end
  if @load_master_status between 'R' and 'T'
  begin
    rollback tran
    exec adm_raiserror 2002112, 'You cannot update a voided shipment!'
    return
  end

  UPDATE dbo.orders_all
   SET dbo.orders_all.date_shipped = @i_date_shipped,
       dbo.orders_all.load_no = @i_load_no
 WHERE order_no = @i_order_no AND ext = @i_order_ext 

  FETCH NEXT FROM loadlupd INTO
  @i_load_no, @i_seq_no, @i_order_no, @i_order_ext, @i_order_list_row_id, @i_freight, @i_date_shipped,
  @d_load_no, @d_seq_no, @d_order_no, @d_order_ext, @d_order_list_row_id, @d_freight, @d_date_shipped
end -- while

close loadlupd
deallocate loadlupd
END

GO
CREATE UNIQUE NONCLUSTERED INDEX [load_list_idx] ON [dbo].[load_list] ([load_no], [order_no], [order_ext]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[load_list] ADD CONSTRAINT [FK_load_list_load_no] FOREIGN KEY ([load_no]) REFERENCES [dbo].[load_master_all] ([load_no])
GO
ALTER TABLE [dbo].[load_list] ADD CONSTRAINT [FK_load_list_orders] FOREIGN KEY ([order_no], [order_ext]) REFERENCES [dbo].[orders_all] ([order_no], [ext])
GO
GRANT REFERENCES ON  [dbo].[load_list] TO [public]
GO
GRANT SELECT ON  [dbo].[load_list] TO [public]
GO
GRANT INSERT ON  [dbo].[load_list] TO [public]
GO
GRANT DELETE ON  [dbo].[load_list] TO [public]
GO
GRANT UPDATE ON  [dbo].[load_list] TO [public]
GO
