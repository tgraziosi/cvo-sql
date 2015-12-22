CREATE TABLE [dbo].[rpt_physval]
(
[batch] [int] NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[orig_qty] [decimal] (20, 8) NULL,
[qty] [decimal] (20, 8) NULL,
[cost] [decimal] (20, 8) NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_physval] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_physval] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_physval] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_physval] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_physval] TO [public]
GO
