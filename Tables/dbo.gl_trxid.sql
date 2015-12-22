CREATE TABLE [dbo].[gl_trxid]
(
[src_trx_id] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[src_trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [gl_trxid_0] ON [dbo].[gl_trxid] ([src_trx_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[gl_trxid] TO [public]
GO
GRANT SELECT ON  [dbo].[gl_trxid] TO [public]
GO
GRANT INSERT ON  [dbo].[gl_trxid] TO [public]
GO
GRANT DELETE ON  [dbo].[gl_trxid] TO [public]
GO
GRANT UPDATE ON  [dbo].[gl_trxid] TO [public]
GO
