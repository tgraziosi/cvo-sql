CREATE TABLE [dbo].[aeg_version_new]
(
[appid] [int] NOT NULL,
[major_version] [int] NOT NULL,
[minor_version] [int] NOT NULL,
[build_no] [int] NOT NULL,
[version] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_installed] [datetime] NOT NULL,
[epr_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[comments] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aeg_version_new] TO [public]
GO
GRANT SELECT ON  [dbo].[aeg_version_new] TO [public]
GO
GRANT INSERT ON  [dbo].[aeg_version_new] TO [public]
GO
GRANT DELETE ON  [dbo].[aeg_version_new] TO [public]
GO
GRANT UPDATE ON  [dbo].[aeg_version_new] TO [public]
GO
