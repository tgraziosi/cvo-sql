CREATE TABLE [dbo].[TDC_STATUS_LIST]
(
[Code] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[TDC_STATUS_LIST] TO [public]
GO
GRANT INSERT ON  [dbo].[TDC_STATUS_LIST] TO [public]
GO
GRANT DELETE ON  [dbo].[TDC_STATUS_LIST] TO [public]
GO
GRANT UPDATE ON  [dbo].[TDC_STATUS_LIST] TO [public]
GO
