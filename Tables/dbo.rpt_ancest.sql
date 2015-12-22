CREATE TABLE [dbo].[rpt_ancest]
(
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [int] NULL,
[tran_code] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ancest] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ancest] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ancest] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ancest] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ancest] TO [public]
GO
