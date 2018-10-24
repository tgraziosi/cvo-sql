CREATE TABLE [dbo].[cvo_artrxage]
(
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_date_int] [int] NULL,
[doc_date] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[parent] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [idx_ar_data] ON [dbo].[cvo_artrxage] ([customer_code], [doc_ctrl_num], [order_ctrl_num]) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_artrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_artrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_artrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_artrxage] TO [public]
GO
