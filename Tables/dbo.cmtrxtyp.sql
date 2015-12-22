CREATE TABLE [dbo].[cmtrxtyp]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmtrxtyp_ind_0] ON [dbo].[cmtrxtyp] ([trx_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmtrxtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrxtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrxtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrxtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrxtyp] TO [public]
GO
