CREATE TABLE [dbo].[cvo_replenishment_log]
(
[row_id] [int] NOT NULL IDENTITY(1, 1),
[replen_group] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[queue_id] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[log_date] [datetime] NULL,
[who_entered] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_replenishment_log] ADD CONSTRAINT [PK__cvo_replenishmen__45F06612] PRIMARY KEY CLUSTERED  ([row_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_replenishment_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replenishment_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replenishment_log] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replenishment_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replenishment_log] TO [public]
GO
