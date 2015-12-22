CREATE TABLE [dbo].[cc_trx_table]
(
[trx_num] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[my_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_trx_table] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_trx_table] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_trx_table] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_trx_table] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_trx_table] TO [public]
GO
