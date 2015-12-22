CREATE TABLE [dbo].[CVO_adhoc_adjust_approval]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[approve] [smallint] NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[created_on] [datetime] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[reason_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[adj_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[date_expires] [datetime] NULL,
[direction] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_adhoc_adjust_approval] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_adhoc_adjust_approval] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_adhoc_adjust_approval] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_adhoc_adjust_approval] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_adhoc_adjust_approval] TO [public]
GO
