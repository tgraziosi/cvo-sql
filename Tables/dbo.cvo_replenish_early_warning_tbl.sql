CREATE TABLE [dbo].[cvo_replenish_early_warning_tbl]
(
[type_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[replenish_min_lvl] [decimal] (20, 0) NULL,
[replenish_max_lvl] [decimal] (20, 0) NULL,
[inv_qty] [decimal] (38, 8) NULL,
[alloc_qty] [decimal] (38, 8) NULL,
[alloc_pct] [decimal] (38, 6) NULL,
[bin_fill_pct] [decimal] (38, 6) NULL,
[replen_qty] [decimal] (38, 8) NULL,
[asofdate] [datetime] NULL,
[Notify_date] [datetime] NULL,
[Ack_Date] [datetime] NULL,
[id] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_replenish_early_warning_tbl] ADD CONSTRAINT [PK__cvo_replenish_ea__0979F2AA] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
