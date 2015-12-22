CREATE TABLE [dbo].[system_log]
(
[timestamp] [timestamp] NOT NULL,
[system_log_id] [int] NOT NULL IDENTITY(1, 1),
[system_datetime] [datetime] NOT NULL CONSTRAINT [DF__system_lo__syste__363DE96F] DEFAULT (getdate()),
[type_flag] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__system_lo__type___37320DA8] DEFAULT ('T'),
[source] [char] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__system_lo__sourc__382631E1] DEFAULT ('???'),
[message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [system_log] ON [dbo].[system_log] ([system_log_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[system_log] TO [public]
GO
GRANT SELECT ON  [dbo].[system_log] TO [public]
GO
GRANT INSERT ON  [dbo].[system_log] TO [public]
GO
GRANT DELETE ON  [dbo].[system_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[system_log] TO [public]
GO
