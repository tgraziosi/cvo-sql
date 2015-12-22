CREATE TABLE [dbo].[arstctrl]
(
[timestamp] [timestamp] NOT NULL,
[loginame] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ctrlnum] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ctrltype] [smallint] NOT NULL,
[spid] [smallint] NOT NULL,
[login_time] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arstctrl] TO [public]
GO
GRANT SELECT ON  [dbo].[arstctrl] TO [public]
GO
GRANT INSERT ON  [dbo].[arstctrl] TO [public]
GO
GRANT DELETE ON  [dbo].[arstctrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[arstctrl] TO [public]
GO
