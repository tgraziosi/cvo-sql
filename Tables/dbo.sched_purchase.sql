CREATE TABLE [dbo].[sched_purchase]
(
[timestamp] [timestamp] NOT NULL,
[sched_item_id] [int] NOT NULL,
[lead_datetime] [datetime] NULL,
[resource_demand_id] [int] NULL,
[vendor_key] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[po_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[release_id] [int] NULL,
[xfer_no] [int] NULL,
[xfer_line] [int] NULL,
[status_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sched_order_id] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[sched_purchase_iu] ON [dbo].[sched_purchase] FOR update AS 
BEGIN

if @@rowcount = 0 return

if not (update(po_no) or update(vendor_key) or update(release_id) or update(xfer_no) or update(xfer_line))
  return

DECLARE @i_sched_item_id int, @i_lead_datetime datetime, @i_resource_demand_id int,
@i_vendor_key varchar(12), @i_po_no varchar(10), @i_release_id int, @i_xfer_no int,
@i_xfer_line int, @i_status_flag char(1),
@d_sched_item_id int, @d_lead_datetime datetime, @d_resource_demand_id int,
@d_vendor_key varchar(12), @d_po_no varchar(10), @d_release_id int, @d_xfer_no int,
@d_xfer_line int, @d_status_flag char(1),
@SI_ind int


DECLARE t700updsche_cursor CURSOR LOCAL STATIC FOR
SELECT i.sched_item_id, i.lead_datetime, i.resource_demand_id, isnull(i.vendor_key,''), 
isnull(i.po_no,''),
isnull(i.release_id,0), isnull(i.xfer_no,0), isnull(i.xfer_line,0), i.status_flag,
d.sched_item_id, d.lead_datetime, d.resource_demand_id, isnull(d.vendor_key,''), 
isnull(d.po_no,''),
isnull(d.release_id,0), isnull(d.xfer_no,0), isnull(d.xfer_line,0), d.status_flag
from inserted i
left outer join deleted d on i.sched_item_id = d.sched_item_id
where (isnull(i.po_no,'') != '' and isnull(i.po_no,'') != isnull(d.po_no,''))
or (isnull(i.vendor_key,'') != '' and isnull(i.vendor_key,'') != isnull(d.vendor_key,''))
or (isnull(i.release_id,0) != isnull(d.release_id,0) and isnull(i.po_no,'') != '')
or (isnull(i.xfer_no,0) != isnull(d.xfer_no,0) and isnull(i.xfer_no,0) != 0)
or (isnull(i.xfer_line,0) != isnull(d.xfer_line,0) and isnull(i.xfer_no,0) != 0)

OPEN t700updsche_cursor

if @@cursor_rows != 0
begin

FETCH NEXT FROM t700updsche_cursor into
@i_sched_item_id, @i_lead_datetime, @i_resource_demand_id, @i_vendor_key, @i_po_no,
@i_release_id, @i_xfer_no, @i_xfer_line, @i_status_flag,
@d_sched_item_id, @d_lead_datetime, @d_resource_demand_id, @d_vendor_key, @d_po_no,
@d_release_id, @d_xfer_no, @d_xfer_line, @d_status_flag

While @@FETCH_STATUS = 0
begin

IF @i_po_no != @d_po_no and @i_po_no != '' and @i_resource_demand_id is not null
BEGIN
	if not exists (select 1
	FROM	resource_demand_group RD
	WHERE	RD.row_id = @i_resource_demand_id)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89306 ,'Illegal column value. RESOURCE_DEMAND_ID not found in RESOURCE_DEMAND_GROUP'
		RETURN
		END
	END

IF @i_vendor_key != @d_vendor_key and @i_vendor_key != ''
	BEGIN

	if not exists (select 1	FROM	dbo.adm_vend_all V
	WHERE	V.vendor_code = @i_vendor_key)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89307 ,'Illegal column value. VENDOR_KEY not found in adm_vend_all'
		RETURN
		END
	END


IF (@i_po_no != @d_po_no or @i_release_id != @d_release_id) and @i_po_no != ''
	BEGIN
	if not exists (select 1 from dbo.releases PR
	WHERE	PR.po_no = @i_po_no
	AND	PR.row_id = @i_release_id)

		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89308, 'Illegal column value. RELEASE not found in RELEASES'
		RETURN
		END
	END


IF (@i_xfer_no != @d_xfer_no  or @i_xfer_line != @d_xfer_line) and @i_xfer_no != 0 
	BEGIN

if not exists (select 1
	FROM	dbo.xfer_list XL
	WHERE	@i_xfer_no = XL.xfer_no
	AND	@i_xfer_line = XL.line_no)
		BEGIN
		ROLLBACK TRANSACTION
		exec adm_raiserror 89309 ,'Illegal column value. XFER_NO, LINE_NO not found in XFERS, XFER_LIST'
		RETURN
		END
	END



FETCH NEXT FROM t700updsche_cursor into
@i_sched_item_id, @i_lead_datetime, @i_resource_demand_id, @i_vendor_key, @i_po_no,
@i_release_id, @i_xfer_no, @i_xfer_line, @i_status_flag,
@d_sched_item_id, @d_lead_datetime, @d_resource_demand_id, @d_vendor_key, @d_po_no,
@d_release_id, @d_xfer_no, @d_xfer_line, @d_status_flag
end -- while
end

CLOSE t700updsche_cursor
DEALLOCATE t700updsche_cursor

END
GO
CREATE NONCLUSTERED INDEX [schpurm1] ON [dbo].[sched_purchase] ([po_no], [release_id], [sched_item_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [sched_purchase] ON [dbo].[sched_purchase] ([sched_item_id]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[sched_purchase] WITH NOCHECK ADD CONSTRAINT [FK_sched_purchase_sched_item] FOREIGN KEY ([sched_item_id]) REFERENCES [dbo].[sched_item] ([sched_item_id]) ON DELETE CASCADE NOT FOR REPLICATION
GO
GRANT REFERENCES ON  [dbo].[sched_purchase] TO [public]
GO
GRANT SELECT ON  [dbo].[sched_purchase] TO [public]
GO
GRANT INSERT ON  [dbo].[sched_purchase] TO [public]
GO
GRANT DELETE ON  [dbo].[sched_purchase] TO [public]
GO
GRANT UPDATE ON  [dbo].[sched_purchase] TO [public]
GO
