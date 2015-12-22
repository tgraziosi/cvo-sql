CREATE TABLE [dbo].[replenishment_groups]
(
[replen_id] [int] NOT NULL IDENTITY(1, 1),
[replen_group] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[perc_to_min] [int] NULL,
[from_bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[to_bin_group] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[in_stock_option] [smallint] NULL,
[in_stock_qty] [decimal] (20, 8) NULL,
[available_option] [smallint] NULL,
[available_qty] [decimal] (20, 8) NULL,
[part_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[who_created] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_created] [datetime] NULL,
[inactive] [smallint] NULL,
[who_inactive] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_inactive] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [replenishment_groups_ind0] ON [dbo].[replenishment_groups] ([replen_group]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[replenishment_groups] TO [public]
GO
GRANT SELECT ON  [dbo].[replenishment_groups] TO [public]
GO
GRANT INSERT ON  [dbo].[replenishment_groups] TO [public]
GO
GRANT DELETE ON  [dbo].[replenishment_groups] TO [public]
GO
GRANT UPDATE ON  [dbo].[replenishment_groups] TO [public]
GO
