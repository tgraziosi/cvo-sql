CREATE TABLE [dbo].[cvo_eyerep_actsls_tbl]
(
[acct_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[TY_ytd_sales] [numeric] (18, 0) NULL,
[LY_ytd_sales] [numeric] (18, 0) NULL,
[ty_r12_sales] [numeric] (18, 0) NULL,
[LY_r12_sales] [numeric] (18, 0) NULL,
[aging30] [numeric] (18, 0) NULL,
[aging60] [numeric] (18, 0) NULL,
[aging90] [numeric] (18, 0) NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_eyerep_actsls_tbl] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_eyerep_actsls_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_eyerep_actsls_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_eyerep_actsls_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_eyerep_actsls_tbl] TO [public]
GO
