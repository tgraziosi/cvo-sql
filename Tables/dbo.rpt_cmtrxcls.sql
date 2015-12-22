CREATE TABLE [dbo].[rpt_cmtrxcls]
(
[trx_type_cls] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type_cls_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[default_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cleared_type] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_cmtrxcls] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_cmtrxcls] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_cmtrxcls] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_cmtrxcls] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_cmtrxcls] TO [public]
GO
