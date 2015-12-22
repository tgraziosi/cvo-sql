CREATE TABLE [dbo].[gltc_currency]
(
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tc_currency_code] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [PK_gltc_currency] ON [dbo].[gltc_currency] ([currency_code]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[gltc_currency] TO [public]
GO
GRANT INSERT ON  [dbo].[gltc_currency] TO [public]
GO
GRANT DELETE ON  [dbo].[gltc_currency] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltc_currency] TO [public]
GO
