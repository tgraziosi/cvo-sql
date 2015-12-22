CREATE TABLE [dbo].[tdc_printers]
(
[print_no] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[port] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[description] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_printers] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_printers] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_printers] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_printers] TO [public]
GO
