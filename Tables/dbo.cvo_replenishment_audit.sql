CREATE TABLE [dbo].[cvo_replenishment_audit]
(
[entry_date] [datetime] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[replen_group] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin_group] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[from_bin_avail] [decimal] (20, 8) NULL,
[to_bin] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin_qty] [decimal] (20, 8) NULL,
[to_bin_avail] [decimal] (20, 8) NULL,
[min_level] [decimal] (20, 8) NULL,
[max_level] [decimal] (20, 8) NULL,
[result] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_replenishment_audit] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_replenishment_audit] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_replenishment_audit] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_replenishment_audit] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_replenishment_audit] TO [public]
GO
