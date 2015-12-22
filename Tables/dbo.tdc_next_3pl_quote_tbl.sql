CREATE TABLE [dbo].[tdc_next_3pl_quote_tbl]
(
[next_quote_id] [int] NULL,
[last_user] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[last_date_updated] [datetime] NULL
) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[tdc_next_3pl_quote_tbl] TO [public]
GO
GRANT INSERT ON  [dbo].[tdc_next_3pl_quote_tbl] TO [public]
GO
GRANT DELETE ON  [dbo].[tdc_next_3pl_quote_tbl] TO [public]
GO
GRANT UPDATE ON  [dbo].[tdc_next_3pl_quote_tbl] TO [public]
GO
