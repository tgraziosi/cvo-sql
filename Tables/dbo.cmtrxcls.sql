CREATE TABLE [dbo].[cmtrxcls]
(
[timestamp] [timestamp] NOT NULL,
[trx_type_cls] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_cls_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cleared_type] [smallint] NOT NULL,
[cash_type] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmtrxcls_ind_0] ON [dbo].[cmtrxcls] ([trx_type_cls]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmtrxcls] TO [public]
GO
GRANT SELECT ON  [dbo].[cmtrxcls] TO [public]
GO
GRANT INSERT ON  [dbo].[cmtrxcls] TO [public]
GO
GRANT DELETE ON  [dbo].[cmtrxcls] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmtrxcls] TO [public]
GO
