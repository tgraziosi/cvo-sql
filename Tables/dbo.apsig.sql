CREATE TABLE [dbo].[apsig]
(
[timestamp] [timestamp] NOT NULL,
[key_value] [varchar] (9) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[font_sequence] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pjl] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apsig_ind_0] ON [dbo].[apsig] ([key_value]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apsig] TO [public]
GO
GRANT SELECT ON  [dbo].[apsig] TO [public]
GO
GRANT INSERT ON  [dbo].[apsig] TO [public]
GO
GRANT DELETE ON  [dbo].[apsig] TO [public]
GO
GRANT UPDATE ON  [dbo].[apsig] TO [public]
GO
