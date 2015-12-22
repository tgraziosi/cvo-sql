CREATE TABLE [dbo].[aeg_error]
(
[appid] [int] NOT NULL,
[langid] [int] NOT NULL,
[error_code] [int] NOT NULL,
[active] [smallint] NOT NULL,
[elevel] [int] NOT NULL,
[text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aegerrorix0] ON [dbo].[aeg_error] ([appid], [langid], [error_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aeg_error] TO [public]
GO
GRANT SELECT ON  [dbo].[aeg_error] TO [public]
GO
GRANT INSERT ON  [dbo].[aeg_error] TO [public]
GO
GRANT DELETE ON  [dbo].[aeg_error] TO [public]
GO
GRANT UPDATE ON  [dbo].[aeg_error] TO [public]
GO
