CREATE TABLE [dbo].[rpt_invactdet]
(
[tran_type] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_no] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[tran_date] [datetime] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_invactdet] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_invactdet] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_invactdet] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_invactdet] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_invactdet] TO [public]
GO
