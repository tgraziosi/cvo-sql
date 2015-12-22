CREATE TABLE [dbo].[eptollin]
(
[timestamp] [timestamp] NOT NULL,
[tolerance_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tolerance_type] [int] NOT NULL,
[active_flag] [smallint] NOT NULL,
[tolerance_basis] [smallint] NOT NULL,
[basis_value] [float] NOT NULL,
[over_flag] [smallint] NOT NULL,
[under_flag] [smallint] NOT NULL,
[display_msg_flag] [smallint] NOT NULL,
[message] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eptollin_idx_0] ON [dbo].[eptollin] ([tolerance_code], [tolerance_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eptollin] TO [public]
GO
GRANT SELECT ON  [dbo].[eptollin] TO [public]
GO
GRANT INSERT ON  [dbo].[eptollin] TO [public]
GO
GRANT DELETE ON  [dbo].[eptollin] TO [public]
GO
GRANT UPDATE ON  [dbo].[eptollin] TO [public]
GO
