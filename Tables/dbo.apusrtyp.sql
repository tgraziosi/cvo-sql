CREATE TABLE [dbo].[apusrtyp]
(
[timestamp] [timestamp] NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[system_trx_type] [smallint] NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dm_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apusrtyp_ind_0] ON [dbo].[apusrtyp] ([user_trx_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apusrtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[apusrtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[apusrtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[apusrtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[apusrtyp] TO [public]
GO
