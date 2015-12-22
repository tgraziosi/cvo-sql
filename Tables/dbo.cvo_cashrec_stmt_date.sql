CREATE TABLE [dbo].[cvo_cashrec_stmt_date]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[stmt_date] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_cashrec_stmt_date] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_cashrec_stmt_date] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_cashrec_stmt_date] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_cashrec_stmt_date] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_cashrec_stmt_date] TO [public]
GO
