CREATE TABLE [dbo].[ar_customer_org_defaults]
(
[timestamp] [timestamp] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ar_customer_org_defaults] TO [public]
GO
GRANT SELECT ON  [dbo].[ar_customer_org_defaults] TO [public]
GO
GRANT INSERT ON  [dbo].[ar_customer_org_defaults] TO [public]
GO
GRANT DELETE ON  [dbo].[ar_customer_org_defaults] TO [public]
GO
GRANT UPDATE ON  [dbo].[ar_customer_org_defaults] TO [public]
GO
