CREATE TABLE [dbo].[rpt_artrxage]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[date_due] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_aging] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amount] [float] NOT NULL,
[rate] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[currency_mask] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[order_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payer_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ref_id] [int] NOT NULL,
[prt_no_trx] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [rpt_artrxage_ind1] ON [dbo].[rpt_artrxage] ([customer_code], [trx_type]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [rpt_artrxage_ind2] ON [dbo].[rpt_artrxage] ([trx_type]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_artrxage] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_artrxage] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_artrxage] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_artrxage] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_artrxage] TO [public]
GO
