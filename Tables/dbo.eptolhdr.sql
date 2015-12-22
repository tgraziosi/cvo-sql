CREATE TABLE [dbo].[eptolhdr]
(
[timestamp] [timestamp] NOT NULL,
[tolerance_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[matching_type] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eptolhdr_idx_0] ON [dbo].[eptolhdr] ([tolerance_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eptolhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[eptolhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[eptolhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[eptolhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[eptolhdr] TO [public]
GO
