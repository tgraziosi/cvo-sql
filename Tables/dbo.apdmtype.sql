CREATE TABLE [dbo].[apdmtype]
(
[timestamp] [timestamp] NOT NULL,
[dm_type] [smallint] NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apdmtype_ind_0] ON [dbo].[apdmtype] ([dm_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apdmtype] TO [public]
GO
GRANT SELECT ON  [dbo].[apdmtype] TO [public]
GO
GRANT INSERT ON  [dbo].[apdmtype] TO [public]
GO
GRANT DELETE ON  [dbo].[apdmtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[apdmtype] TO [public]
GO
