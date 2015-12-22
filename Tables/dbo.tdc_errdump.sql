CREATE TABLE [dbo].[tdc_errdump]
(
[LogDate] [datetime] NOT NULL,
[ServerName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[DataName] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[UserID] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Computer] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ErrID] [numeric] (18, 0) NOT NULL,
[ErrDescription] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[Routine] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[SQLString] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_errdump] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_errdump] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_errdump] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_errdump] TO [public]
GO
