CREATE TABLE [dbo].[adm_price_catalog]
(
[timestamp] [timestamp] NOT NULL,
[catalog_id] [int] NOT NULL IDENTITY(1, 1),
[catalog_cd] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_key] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[active_ind] [int] NOT NULL,
[type] [int] NOT NULL,
[start_date] [datetime] NULL,
[end_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [adm_price_catalog_1] ON [dbo].[adm_price_catalog] ([catalog_cd], [type]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [adm_price_catalog_0] ON [dbo].[adm_price_catalog] ([catalog_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_price_catalog] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_price_catalog] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_price_catalog] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_price_catalog] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_price_catalog] TO [public]
GO
