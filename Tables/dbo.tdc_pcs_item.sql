CREATE TABLE [dbo].[tdc_pcs_item]
(
[child_serial_no] [int] NOT NULL,
[location] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[part_no] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[lot_ser] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bin_no] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[quantity] [decimal] (20, 8) NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_pcs_item] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_pcs_item] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_pcs_item] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_pcs_item] TO [public]
GO
