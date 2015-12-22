CREATE TABLE [dbo].[tdc_manifest_initial_setup]
(
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[carrier] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[street_1] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[street_2] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[city] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[state] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[county] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zip] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[country] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[phone_no] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pager_no] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[fax_no] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_no] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[meter] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tran_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subscription_1] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subscription_2] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_manifest_initial_setup] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_manifest_initial_setup] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_manifest_initial_setup] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_manifest_initial_setup] TO [public]
GO
