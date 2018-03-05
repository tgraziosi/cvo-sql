CREATE TABLE [dbo].[artrxpdt]
(
[timestamp] [timestamp] NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[date_aging] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[amt_wr_off] [float] NOT NULL,
[void_flag] [smallint] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_type] [smallint] NOT NULL,
[amt_tot_chg] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[inv_amt_applied] [float] NOT NULL,
[inv_amt_disc_taken] [float] NOT NULL,
[inv_amt_wr_off] [float] NOT NULL,
[payer_cust_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__artrxpdt__writeo__0BA3CD1B] DEFAULT (''),
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [artrxpdt_ind_0] ON [dbo].[artrxpdt] ([customer_code], [doc_ctrl_num], [trx_type], [trx_ctrl_num], [sequence_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [artrxpdt_ind_4] ON [dbo].[artrxpdt] ([sub_apply_num], [sub_apply_type]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [artrxpdt_ind_1] ON [dbo].[artrxpdt] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[artrxpdt] TO [public]
GO
GRANT SELECT ON  [dbo].[artrxpdt] TO [public]
GO
GRANT INSERT ON  [dbo].[artrxpdt] TO [public]
GO
GRANT DELETE ON  [dbo].[artrxpdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[artrxpdt] TO [public]
GO
