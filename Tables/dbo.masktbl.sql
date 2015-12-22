CREATE TABLE [dbo].[masktbl]
(
[timestamp] [timestamp] NOT NULL,
[mask_id] [int] NOT NULL,
[mask_name] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [masktbl_ind_0] ON [dbo].[masktbl] ([mask_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[masktbl] TO [public]
GO
GRANT SELECT ON  [dbo].[masktbl] TO [public]
GO
GRANT INSERT ON  [dbo].[masktbl] TO [public]
GO
GRANT DELETE ON  [dbo].[masktbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[masktbl] TO [public]
GO
