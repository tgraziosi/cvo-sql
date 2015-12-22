CREATE TABLE [dbo].[tdc_3pl_quotation_tbl]
(
[quote_id] [int] NOT NULL,
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[active] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[is_contract] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract_length] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quote_currency] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contract_start_date] [datetime] NULL,
[contract_terms] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contact_number] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[created_date] [datetime] NULL CONSTRAINT [DF__tdc_3pl_q__creat__1D30ADD5] DEFAULT (getdate()),
[last_modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[last_modified_date] [datetime] NULL CONSTRAINT [DF__tdc_3pl_q__last___1E24D20E] DEFAULT (getdate())
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_quotation_tbl_idx2] ON [dbo].[tdc_3pl_quotation_tbl] ([cust_code]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [tdc_3pl_quotation_tbl_idx1] ON [dbo].[tdc_3pl_quotation_tbl] ([quote_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_quotation_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_quotation_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_quotation_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_quotation_tbl] TO [public]
GO
