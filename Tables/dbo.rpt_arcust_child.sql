CREATE TABLE [dbo].[rpt_arcust_child]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[relation_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[child] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcust_child] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcust_child] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcust_child] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcust_child] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcust_child] TO [public]
GO
