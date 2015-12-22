CREATE TABLE [dbo].[rpt_shipsum]
(
[region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [decimal] (18, 0) NULL,
[cr_shipped] [decimal] (18, 0) NULL,
[price] [decimal] (18, 0) NULL,
[cust_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_1] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[group_2] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_shipsum] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_shipsum] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_shipsum] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_shipsum] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_shipsum] TO [public]
GO
