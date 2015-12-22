CREATE TABLE [dbo].[ap_vendor_org_defaults]
(
[timestamp] [timestamp] NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[organization_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ap_vendor_org_defaults] TO [public]
GO
GRANT SELECT ON  [dbo].[ap_vendor_org_defaults] TO [public]
GO
GRANT INSERT ON  [dbo].[ap_vendor_org_defaults] TO [public]
GO
GRANT DELETE ON  [dbo].[ap_vendor_org_defaults] TO [public]
GO
GRANT UPDATE ON  [dbo].[ap_vendor_org_defaults] TO [public]
GO
