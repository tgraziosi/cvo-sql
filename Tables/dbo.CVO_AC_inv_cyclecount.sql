CREATE TABLE [dbo].[CVO_AC_inv_cyclecount]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[issue_date] [datetime] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[category] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[style] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[year] [int] NULL,
[month] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_AC_inv_cyclecount] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_AC_inv_cyclecount] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_AC_inv_cyclecount] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_AC_inv_cyclecount] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_AC_inv_cyclecount] TO [public]
GO
