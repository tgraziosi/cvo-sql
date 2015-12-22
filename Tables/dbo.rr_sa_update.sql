CREATE TABLE [dbo].[rr_sa_update]
(
[id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sequence_id] [int] NULL,
[contract_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[contract_sequence_id] [int] NULL,
[contract_end_date] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_sequence_id] [int] NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_order_no] [int] NULL,
[source_ext] [int] NULL,
[svc_agreement_id] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[eai_flag] [int] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rr_sa_update] TO [public]
GO
GRANT SELECT ON  [dbo].[rr_sa_update] TO [public]
GO
GRANT INSERT ON  [dbo].[rr_sa_update] TO [public]
GO
GRANT DELETE ON  [dbo].[rr_sa_update] TO [public]
GO
GRANT UPDATE ON  [dbo].[rr_sa_update] TO [public]
GO
