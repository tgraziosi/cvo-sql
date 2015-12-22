CREATE TABLE [dbo].[tdc_wow_cust_code]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[all_cust_code] [int] NULL CONSTRAINT [DF__tdc_wow_c__all_c__1F6DFC02] DEFAULT ((0)),
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_wow_cust_code_idx1] ON [dbo].[tdc_wow_cust_code] ([userid], [customer_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_wow_cust_code] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_wow_cust_code] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_wow_cust_code] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_wow_cust_code] TO [public]
GO
