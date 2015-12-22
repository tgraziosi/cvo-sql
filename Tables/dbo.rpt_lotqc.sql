CREATE TABLE [dbo].[rpt_lotqc]
(
[qc_no] [int] NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[vendor] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[result1] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[result2] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[result3] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[result4] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qty] [decimal] (20, 8) NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_lotqc] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_lotqc] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_lotqc] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_lotqc] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_lotqc] TO [public]
GO
