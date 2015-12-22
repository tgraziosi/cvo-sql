CREATE TABLE [dbo].[so_usrstat]
(
[timestamp] [timestamp] NOT NULL,
[user_stat_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_code] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_stat_desc] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_flag] [smallint] NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cat1] ON [dbo].[so_usrstat] ([user_stat_code], [status_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[so_usrstat] TO [public]
GO
GRANT SELECT ON  [dbo].[so_usrstat] TO [public]
GO
GRANT INSERT ON  [dbo].[so_usrstat] TO [public]
GO
GRANT DELETE ON  [dbo].[so_usrstat] TO [public]
GO
GRANT UPDATE ON  [dbo].[so_usrstat] TO [public]
GO
