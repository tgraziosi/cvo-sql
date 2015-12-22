CREATE TABLE [dbo].[arinppdt]
(
[timestamp] [timestamp] NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [int] NOT NULL,
[trx_type] [smallint] NOT NULL,
[apply_to_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[apply_trx_type] [smallint] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_aging] [int] NOT NULL,
[amt_applied] [float] NOT NULL,
[amt_disc_taken] [float] NOT NULL,
[wr_off_flag] [smallint] NOT NULL,
[amt_max_wr_off] [float] NOT NULL,
[void_flag] [smallint] NOT NULL,
[line_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_apply_type] [smallint] NOT NULL,
[amt_tot_chg] [float] NOT NULL,
[amt_paid_to_date] [float] NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_doc] [int] NOT NULL,
[amt_inv] [float] NOT NULL,
[gain_home] [float] NOT NULL,
[gain_oper] [float] NOT NULL,
[inv_amt_applied] [float] NOT NULL,
[inv_amt_disc_taken] [float] NOT NULL,
[inv_amt_max_wr_off] [float] NOT NULL,
[inv_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[writeoff_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__writeo__2EA2253E] DEFAULT (''),
[writeoff_amount] [float] NULL CONSTRAINT [DF__arinppdt__writeo__2F964977] DEFAULT ((0)),
[cross_rate] [float] NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[chargeback] [smallint] NULL CONSTRAINT [DF__arinppdt__charge__0F01BEB8] DEFAULT ((0)),
[chargeref] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__charge__0FF5E2F1] DEFAULT (''),
[cb_store_number] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__cb_sto__10EA072A] DEFAULT (''),
[cb_reason_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__cb_rea__11DE2B63] DEFAULT (''),
[cb_responsibility_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__cb_res__12D24F9C] DEFAULT (''),
[cb_reason_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__arinppdt__cb_rea__13C673D5] DEFAULT (''),
[chargeamt] [float] NULL CONSTRAINT [DF__arinppdt__charge__14BA980E] DEFAULT ((0.0))
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [arinppdt_ind_1] ON [dbo].[arinppdt] ([apply_to_num], [trx_type]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arinppdt_ind_0] ON [dbo].[arinppdt] ([trx_ctrl_num], [trx_type], [sequence_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arinppdt] TO [public]
GO
GRANT SELECT ON  [dbo].[arinppdt] TO [public]
GO
GRANT INSERT ON  [dbo].[arinppdt] TO [public]
GO
GRANT DELETE ON  [dbo].[arinppdt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arinppdt] TO [public]
GO
