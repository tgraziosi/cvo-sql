CREATE TABLE [dbo].[EAI_credit_memo_ord_xref]
(
[fo_order_id] [nvarchar] (64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[fo_order_num] [nvarchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [EAI_credit_memo_ord_xref_ind_0] ON [dbo].[EAI_credit_memo_ord_xref] ([fo_order_id]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[EAI_credit_memo_ord_xref] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_credit_memo_ord_xref] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_credit_memo_ord_xref] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_credit_memo_ord_xref] TO [public]
GO
