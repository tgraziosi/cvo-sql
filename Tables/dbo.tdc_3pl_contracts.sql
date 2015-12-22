CREATE TABLE [dbo].[tdc_3pl_contracts]
(
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contract_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_period] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[processed_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[processed_date] [datetime] NULL,
[created_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[created_date] [datetime] NOT NULL,
[modified_by] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[modified_date] [datetime] NOT NULL,
[process_date_from] [datetime] NULL,
[process_date_to] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[tdc_3pl_contracts] ADD CONSTRAINT [pk_tdc_3pl_contracts] PRIMARY KEY NONCLUSTERED  ([cust_code], [ship_to], [contract_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_contracts_idx1] ON [dbo].[tdc_3pl_contracts] ([cust_code], [ship_to], [contract_name]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_contracts] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_contracts] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_contracts] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_contracts] TO [public]
GO
