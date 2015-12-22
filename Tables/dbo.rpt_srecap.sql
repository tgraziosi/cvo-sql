CREATE TABLE [dbo].[rpt_srecap]
(
[order_no] [int] NULL,
[order_ext] [int] NULL,
[ship_to_region] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[shipped] [decimal] (18, 0) NULL,
[price] [decimal] (18, 0) NULL,
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_shipped] [datetime] NOT NULL,
[cr_shipped] [decimal] (18, 0) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_srecap] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_srecap] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_srecap] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_srecap] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_srecap] TO [public]
GO
