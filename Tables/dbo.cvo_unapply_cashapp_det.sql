CREATE TABLE [dbo].[cvo_unapply_cashapp_det]
(
[row_id] [int] NULL,
[seq_id] [int] NULL,
[payer_cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pay_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[customer_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[applied_amount] [float] NULL,
[process_flag] [int] NULL,
[adj_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_unapply_cashapp_det] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_unapply_cashapp_det] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_unapply_cashapp_det] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_unapply_cashapp_det] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_unapply_cashapp_det] TO [public]
GO
