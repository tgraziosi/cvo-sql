CREATE TABLE [dbo].[so_usrpry]
(
[timestamp] [timestamp] NOT NULL,
[user_priority_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[priority_level] [smallint] NULL,
[priority_cod_def] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[void_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [so_usrpry_idx] ON [dbo].[so_usrpry] ([user_priority_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[so_usrpry] TO [public]
GO
GRANT SELECT ON  [dbo].[so_usrpry] TO [public]
GO
GRANT INSERT ON  [dbo].[so_usrpry] TO [public]
GO
GRANT DELETE ON  [dbo].[so_usrpry] TO [public]
GO
GRANT UPDATE ON  [dbo].[so_usrpry] TO [public]
GO
