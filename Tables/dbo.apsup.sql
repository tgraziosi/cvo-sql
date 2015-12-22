CREATE TABLE [dbo].[apsup]
(
[timestamp] [timestamp] NOT NULL,
[item_code] [varchar] (18) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vendor_part_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[comment] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [apsup_ind_0] ON [dbo].[apsup] ([item_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apsup] TO [public]
GO
GRANT SELECT ON  [dbo].[apsup] TO [public]
GO
GRANT INSERT ON  [dbo].[apsup] TO [public]
GO
GRANT DELETE ON  [dbo].[apsup] TO [public]
GO
GRANT UPDATE ON  [dbo].[apsup] TO [public]
GO
