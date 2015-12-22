CREATE TABLE [dbo].[eptoltyp]
(
[timestamp] [timestamp] NOT NULL,
[tolerance_type] [int] NOT NULL,
[tolerance_type_desc] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [eptoltyp_idx_0] ON [dbo].[eptoltyp] ([tolerance_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[eptoltyp] TO [public]
GO
GRANT SELECT ON  [dbo].[eptoltyp] TO [public]
GO
GRANT INSERT ON  [dbo].[eptoltyp] TO [public]
GO
GRANT DELETE ON  [dbo].[eptoltyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[eptoltyp] TO [public]
GO
