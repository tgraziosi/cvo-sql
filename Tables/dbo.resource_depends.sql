CREATE TABLE [dbo].[resource_depends]
(
[timestamp] [timestamp] NOT NULL,
[batch_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NOT NULL,
[avail_date] [datetime] NOT NULL,
[avail_source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[avail_source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demand_source] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[demand_source_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[demand_date] [datetime] NOT NULL,
[ilevel] [int] NULL,
[status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[avail_row_id] [int] NULL,
[demand_row_id] [int] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t601delresdep]
ON [dbo].[resource_depends] 
FOR DELETE 
AS
BEGIN

UPDATE	dbo.resource_avail
SET	qty = r.qty + i.qty,
	commit_ed = r.commit_ed - i.qty
FROM	deleted i,
	dbo.resource_avail r
WHERE	r.row_id = i.avail_row_id

UPDATE	dbo.resource_demand
SET	qty = r.qty + i.qty,
	commit_ed = r.commit_ed - i.qty
FROM	deleted i,
	dbo.resource_demand r
WHERE	r.row_id=i.demand_row_id

RETURN
END
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[t601insresdep]
ON [dbo].[resource_depends] 
FOR INSERT
AS
BEGIN

UPDATE	resource_avail
SET	qty = r.qty - i.qty,
	commit_ed = r.commit_ed + i.qty
FROM	inserted i,
	resource_avail r
WHERE	r.row_id=i.avail_row_id

UPDATE	resource_demand
SET	qty = r.qty - i.qty,
	commit_ed = r.commit_ed + i.qty
FROM	inserted i,
	resource_demand r 
WHERE	r.row_id=i.demand_row_id

RETURN
END
GO
CREATE CLUSTERED INDEX [resdepend1] ON [dbo].[resource_depends] ([batch_id], [ilevel], [location], [part_no], [demand_date], [demand_source], [demand_source_no], [status]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [resdep2] ON [dbo].[resource_depends] ([location], [part_no], [avail_date]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[resource_depends] ADD CONSTRAINT [FK_resource_depends_resource_batch_batch_id] FOREIGN KEY ([batch_id]) REFERENCES [dbo].[resource_batch] ([batch_id])
GO
GRANT REFERENCES ON  [dbo].[resource_depends] TO [public]
GO
GRANT SELECT ON  [dbo].[resource_depends] TO [public]
GO
GRANT INSERT ON  [dbo].[resource_depends] TO [public]
GO
GRANT DELETE ON  [dbo].[resource_depends] TO [public]
GO
GRANT UPDATE ON  [dbo].[resource_depends] TO [public]
GO
