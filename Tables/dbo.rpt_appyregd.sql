CREATE TABLE [dbo].[rpt_appyregd]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[invoice_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[po_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[home_oper_gain] [float] NOT NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_applied] [datetime] NOT NULL,
[status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[link] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[local_batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[local_hdate_applied] [datetime] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_appyregd] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_appyregd] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_appyregd] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_appyregd] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_appyregd] TO [public]
GO
