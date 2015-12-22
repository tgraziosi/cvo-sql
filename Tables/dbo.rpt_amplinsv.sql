CREATE TABLE [dbo].[rpt_amplinsv]
(
[quarter] [int] NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[period_end_date] [datetime] NULL,
[cost] [float] NULL,
[percentage_cost] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_amplinsv] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_amplinsv] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_amplinsv] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_amplinsv] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_amplinsv] TO [public]
GO
