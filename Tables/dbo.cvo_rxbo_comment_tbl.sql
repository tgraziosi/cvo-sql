CREATE TABLE [dbo].[cvo_rxbo_comment_tbl]
(
[order_no] [int] NULL,
[ext] [int] NULL,
[call_date] [datetime] NULL,
[call_user] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [pk_cvo_rxbo_comment] ON [dbo].[cvo_rxbo_comment_tbl] ([order_no], [ext]) ON [PRIMARY]
GO
