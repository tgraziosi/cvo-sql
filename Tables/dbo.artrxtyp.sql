CREATE TABLE [dbo].[artrxtyp]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_desc] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [artrxtyp_ind_0] ON [dbo].[artrxtyp] ([trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxtyp_ind_1] ON [dbo].[artrxtyp] ([trx_type_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxtyp] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxtyp] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxtyp] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxtyp] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxtyp] TO [public]
GO
