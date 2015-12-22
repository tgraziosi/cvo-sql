CREATE TABLE [dbo].[tdc_lookup_help]
(
[language] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[source] [varchar] (2) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[module] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trans] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[help_no] [int] NOT NULL,
[help_msg] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [tdc_lookup_help_Index] ON [dbo].[tdc_lookup_help] ([language], [module], [trans], [help_no]) WITH (FILLFACTOR=100) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_lookup_help] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_lookup_help] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_lookup_help] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_lookup_help] TO [public]
GO
