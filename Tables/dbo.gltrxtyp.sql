CREATE TABLE [dbo].[gltrxtyp]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [gltrxtyp_ind_0] ON [dbo].[gltrxtyp] ([trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gltrxtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[gltrxtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[gltrxtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[gltrxtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltrxtyp] TO [public]
GO
