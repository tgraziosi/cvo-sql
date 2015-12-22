CREATE TABLE [dbo].[orders_auto_po]
(
[timestamp] [timestamp] NOT NULL,
[row_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NOT NULL,
[line_no] [int] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[req_ship_date] [datetime] NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[internal_po_ind] [int] NULL,
[approval_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t500insoap] ON [dbo].[orders_auto_po] 
FOR INSERT
AS
begin
update orders_auto_po
set vendor=x.vendor,
uom=isnull(x.uom,'EA')
from inserted i, inv_master x (nolock)
where i.row_id=orders_auto_po.row_id and i.part_no = x.part_no and isnull(i.uom,'') = ''
end

GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t700deloap] ON [dbo].[orders_auto_po] FOR delete AS 
BEGIN

DECLARE @d_row_id int, @d_location varchar(10), @d_part_no varchar(30), @d_vendor varchar(12),
@d_order_no int, @d_line_no int, @d_qty decimal(20,8), @d_uom char(2), @d_status char(1),
@d_req_ship_date datetime, @d_po_no varchar(16), @d_part_type char(1)

DECLARE t700delorde_cursor CURSOR LOCAL STATIC FOR
SELECT d.row_id, d.location, d.part_no, d.vendor, d.order_no, d.line_no, d.qty, d.uom, d.status,
d.req_ship_date, d.po_no, d.part_type
from deleted d

OPEN t700delorde_cursor
FETCH NEXT FROM t700delorde_cursor into
@d_row_id, @d_location, @d_part_no, @d_vendor, @d_order_no, @d_line_no, @d_qty, @d_uom,
@d_status, @d_req_ship_date, @d_po_no, @d_part_type

While @@FETCH_STATUS = 0
begin
  if @d_po_no is not NULL
  begin
    update releases
    set ord_line = NULL
    where po_no = @d_po_no and part_no = @d_part_no and ord_line = @d_line_no
  end


FETCH NEXT FROM t700delorde_cursor into
@d_row_id, @d_location, @d_part_no, @d_vendor, @d_order_no, @d_line_no, @d_qty, @d_uom,
@d_status, @d_req_ship_date, @d_po_no, @d_part_type
end -- while

CLOSE t700delorde_cursor
DEALLOCATE t700delorde_cursor

END
GO
CREATE UNIQUE CLUSTERED INDEX [t500insoap] ON [dbo].[orders_auto_po] ([order_no], [line_no], [part_no], [po_no]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [t600insoap2] ON [dbo].[orders_auto_po] ([po_no], [part_no], [line_no], [order_no]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[orders_auto_po] TO [public]
GO
GRANT SELECT ON  [dbo].[orders_auto_po] TO [public]
GO
GRANT INSERT ON  [dbo].[orders_auto_po] TO [public]
GO
GRANT DELETE ON  [dbo].[orders_auto_po] TO [public]
GO
GRANT UPDATE ON  [dbo].[orders_auto_po] TO [public]
GO
