CREATE TABLE [dbo].[sched_order]
(
[timestamp] [timestamp] NOT NULL,
[sched_id] [int] NOT NULL,
[sched_order_id] [int] NOT NULL IDENTITY(1, 1),
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[done_datetime] [datetime] NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[uom_qty] [float] NOT NULL,
[uom] [char] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_priority_id] [int] NOT NULL,
[source_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[order_line] [int] NULL,
[order_line_kit] [int] NULL,
[prod_no] [int] NULL,
[prod_ext] [int] NULL,
[action_datetime] [datetime] NULL,
[action_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__sched_ord__actio__774C92BD] DEFAULT ('?')
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[sched_order_iu] ON [dbo].[sched_order] FOR update AS 
BEGIN

if @@rowcount = 0 return

if not (update (order_no) or update (order_ext) or update(order_line) or update(source_flag))  
  return


DECLARE @i_sched_id int, @i_sched_order_id int, @i_location varchar(10), @i_done_datetime datetime,
@i_part_no varchar(30), @i_uom_qty float, @i_uom char(2), @i_order_priority_id int,
@i_source_flag char(1), @i_order_no int, @i_order_ext int, @i_order_line int,
@i_order_line_kit int, @i_prod_no int, @i_prod_ext int, @i_action_datetime datetime,
@i_action_flag char(1),
@d_sched_id int, @d_sched_order_id int, @d_location varchar(10), @d_done_datetime datetime,
@d_part_no varchar(30), @d_uom_qty float, @d_uom char(2), @d_order_priority_id int,
@d_source_flag char(1), @d_order_no int, @d_order_ext int, @d_order_line int,
@d_order_line_kit int, @d_prod_no int, @d_prod_ext int, @d_action_datetime datetime,
@d_action_flag char(1),
@SL_ind int, @OP_ind int,
@msg varchar(255)

DECLARE t700updsche_cursor CURSOR LOCAL STATIC FOR
SELECT i.sched_id, i.sched_order_id, i.location, i.done_datetime, i.part_no, i.uom_qty, i.uom,
i.order_priority_id, i.source_flag, 
isnull(i.order_no,0), isnull(i.order_ext,0), isnull(i.order_line,0), i.order_line_kit,
i.prod_no, i.prod_ext, i.action_datetime, i.action_flag,
d.sched_id, d.sched_order_id, d.location, d.done_datetime, d.part_no, d.uom_qty, d.uom,
d.order_priority_id, d.source_flag, 
isnull(d.order_no,0), isnull(d.order_ext,0), isnull(d.order_line,0), d.order_line_kit,
d.prod_no, d.prod_ext, d.action_datetime, d.action_flag
from inserted i
left outer join deleted d on i.sched_order_id=d.sched_order_id
where i.source_flag in ('C','T')

OPEN t700updsche_cursor

if @@cursor_rows != 0
begin

FETCH NEXT FROM t700updsche_cursor into
@i_sched_id, @i_sched_order_id, @i_location, @i_done_datetime, @i_part_no, @i_uom_qty, @i_uom,
@i_order_priority_id, @i_source_flag, @i_order_no, @i_order_ext, @i_order_line,
@i_order_line_kit, @i_prod_no, @i_prod_ext, @i_action_datetime, @i_action_flag,
@d_sched_id, @d_sched_order_id, @d_location, @d_done_datetime, @d_part_no, @d_uom_qty, @d_uom,
@d_order_priority_id, @d_source_flag, @d_order_no, @d_order_ext, @d_order_line,
@d_order_line_kit, @d_prod_no, @d_prod_ext, @d_action_datetime, @d_action_flag

While @@FETCH_STATUS = 0
begin


if (@i_order_no != @d_order_no or @i_order_ext != @d_order_ext 
  or @i_order_line != @d_order_line
  or @i_source_flag != isnull(@d_source_flag,'')) and @i_order_no !=0
begin
  if @i_source_flag = 'C'
begin
if not exists (select 1 
	FROM	dbo.ord_list OL
	WHERE	OL.order_no = @i_order_no
	AND	OL.order_ext = @i_order_ext
	AND	OL.line_no = @i_order_line)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89203 ,'Illegal column value. ORDER_NO,ORDER_EXT,LINE_NO not found in ORD_LIST'
		RETURN
		END
end
if @i_source_flag = 'T'
begin
if not exists (select 1 
	FROM	dbo.xfer_list XL
	WHERE	XL.xfer_no = @i_order_no
	AND	XL.line_no = @i_order_line)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89204, 'Illegal column value. XFER_NO,LINE_NO not found in XFER_LIST'
		RETURN
		END
	END
end

FETCH NEXT FROM t700updsche_cursor into
@i_sched_id, @i_sched_order_id, @i_location, @i_done_datetime, @i_part_no, @i_uom_qty, @i_uom,
@i_order_priority_id, @i_source_flag, @i_order_no, @i_order_ext, @i_order_line,
@i_order_line_kit, @i_prod_no, @i_prod_ext, @i_action_datetime, @i_action_flag,
@d_sched_id, @d_sched_order_id, @d_location, @d_done_datetime, @d_part_no, @d_uom_qty, @d_uom,
@d_order_priority_id, @d_source_flag, @d_order_no, @d_order_ext, @d_order_line,
@d_order_line_kit, @d_prod_no, @d_prod_ext, @d_action_datetime, @d_action_flag
end -- while
end

CLOSE t700updsche_cursor
DEALLOCATE t700updsche_cursor

END
GO
ALTER TABLE [dbo].[sched_order] ADD CONSTRAINT [sched_order_source_flag_cc1] CHECK (([source_flag]='N' OR [source_flag]='M' OR [source_flag]='E' OR [source_flag]='J' OR [source_flag]='T' OR [source_flag]='A' OR [source_flag]='F' OR [source_flag]='C'))
GO
CREATE NONCLUSTERED INDEX [schordm1] ON [dbo].[sched_order] ([sched_id], [order_no], [order_ext], [source_flag]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [schordm2] ON [dbo].[sched_order] ([sched_id], [source_flag], [order_no], [order_ext]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_order] ON [dbo].[sched_order] ([sched_order_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_order] WITH NOCHECK ADD CONSTRAINT [FK_sched_order_order_priority] FOREIGN KEY ([order_priority_id]) REFERENCES [dbo].[order_priority] ([order_priority_id]) NOT FOR REPLICATION
GO
ALTER TABLE [dbo].[sched_order] WITH NOCHECK ADD CONSTRAINT [FK_sched_order_sched_location] FOREIGN KEY ([sched_id], [location]) REFERENCES [dbo].[sched_location] ([sched_id], [location]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_order] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_order] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_order] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_order] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_order] TO [public]
GO
