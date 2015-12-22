CREATE TABLE [dbo].[tdc_physical]
(
[phy_batch] [int] NOT NULL,
[phy_no] [int] NOT NULL,
[child_serial_no] [int] NOT NULL,
[qty] [decimal] (20, 8) NOT NULL,
[count_date] [datetime] NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_physical] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_physical] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_physical] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_physical] TO [public]
GO
