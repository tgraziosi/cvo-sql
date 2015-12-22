CREATE TABLE [dbo].[cvo_auto_posting_errors]
(
[error_date] [datetime] NULL,
[batch_no] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_no] [int] NULL,
[order_ext] [int] NULL,
[error_desc] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_auto_posting_errors] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_auto_posting_errors] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_auto_posting_errors] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_auto_posting_errors] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_auto_posting_errors] TO [public]
GO
