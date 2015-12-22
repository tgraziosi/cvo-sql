CREATE TABLE [dbo].[arconcry]
(
[timestamp] [timestamp] NOT NULL,
[table_name] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pid] [int] NOT NULL,
[last_save_time] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arconcry_ind_0] ON [dbo].[arconcry] ([table_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arconcry] TO [public]
GO
GRANT SELECT ON  [dbo].[arconcry] TO [public]
GO
GRANT INSERT ON  [dbo].[arconcry] TO [public]
GO
GRANT DELETE ON  [dbo].[arconcry] TO [public]
GO
GRANT UPDATE ON  [dbo].[arconcry] TO [public]
GO
