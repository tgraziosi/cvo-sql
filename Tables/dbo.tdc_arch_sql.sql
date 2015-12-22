CREATE TABLE [dbo].[tdc_arch_sql]
(
[SQLString] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_archived] [datetime] NULL,
[who_archived] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_arch_sql] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_arch_sql] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_arch_sql] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_arch_sql] TO [public]
GO
