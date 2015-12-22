CREATE TABLE [dbo].[tdc_3pl_assigned_parts]
(
[cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ship_to] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[contract_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[filter_value] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_assigned_parts_idx2] ON [dbo].[tdc_3pl_assigned_parts] ([cust_code], [ship_to], [contract_name]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [tdc_3pl_assigned_parts_idx1] ON [dbo].[tdc_3pl_assigned_parts] ([cust_code], [type]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_3pl_assigned_parts] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_3pl_assigned_parts] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_3pl_assigned_parts] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_3pl_assigned_parts] TO [public]
GO
