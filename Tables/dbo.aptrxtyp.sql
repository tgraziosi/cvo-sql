CREATE TABLE [dbo].[aptrxtyp]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [aptrxtyp_ind_0] ON [dbo].[aptrxtyp] ([trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [aptrxtyp_ind_1] ON [dbo].[aptrxtyp] ([trx_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[aptrxtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[aptrxtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[aptrxtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[aptrxtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[aptrxtyp] TO [public]
GO
