CREATE TABLE [dbo].[ibtrxtype]
(
[timestamp] [timestamp] NOT NULL,
[trx_type] [int] NOT NULL,
[description] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[type] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ibtrxtype_i1] ON [dbo].[ibtrxtype] ([trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ibtrxtype] TO [public]
GO
GRANT SELECT ON  [dbo].[ibtrxtype] TO [public]
GO
GRANT INSERT ON  [dbo].[ibtrxtype] TO [public]
GO
GRANT DELETE ON  [dbo].[ibtrxtype] TO [public]
GO
GRANT UPDATE ON  [dbo].[ibtrxtype] TO [public]
GO
