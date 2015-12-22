CREATE TABLE [dbo].[tdc_progress]
(
[progress_value] [decimal] (20, 8) NULL,
[message_value] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_progress] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_progress] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_progress] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_progress] TO [public]
GO
