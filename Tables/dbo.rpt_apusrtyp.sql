CREATE TABLE [dbo].[rpt_apusrtyp]
(
[timestamp] [timestamp] NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[db_type] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_apusrtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_apusrtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_apusrtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_apusrtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_apusrtyp] TO [public]
GO
