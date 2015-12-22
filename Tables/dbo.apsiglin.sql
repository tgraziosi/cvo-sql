CREATE TABLE [dbo].[apsiglin]
(
[timestamp] [timestamp] NOT NULL,
[key_value] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[character_line] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apsiglin_ind_0] ON [dbo].[apsiglin] ([key_value], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apsiglin] TO [public]
GO
GRANT SELECT ON  [dbo].[apsiglin] TO [public]
GO
GRANT INSERT ON  [dbo].[apsiglin] TO [public]
GO
GRANT DELETE ON  [dbo].[apsiglin] TO [public]
GO
GRANT UPDATE ON  [dbo].[apsiglin] TO [public]
GO
