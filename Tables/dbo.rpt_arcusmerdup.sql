CREATE TABLE [dbo].[rpt_arcusmerdup]
(
[customer_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code2] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcusmerdup] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcusmerdup] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcusmerdup] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcusmerdup] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcusmerdup] TO [public]
GO
