CREATE TABLE [dbo].[arvalpyt]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[non_ar_flag] [smallint] NOT NULL,
[non_ar_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[date_doc] [int] NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[payment_type] [smallint] NOT NULL,
[amt_payment] [float] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deposit_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[bal_fwd_flag] [smallint] NOT NULL,
[printed_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[wr_off_flag] [smallint] NOT NULL,
[on_acct_flag] [smallint] NOT NULL,
[user_id] [smallint] NOT NULL,
[max_wr_off] [float] NOT NULL,
[days_past_due] [int] NOT NULL,
[void_type] [smallint] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[origin_module_flag] [smallint] NULL,
[process_group_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[temp_flag] [smallint] NULL,
[source_trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_trx_type] [smallint] NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[amt_discount] [float] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arvalpyt] TO [public]
GO
GRANT SELECT ON  [dbo].[arvalpyt] TO [public]
GO
GRANT INSERT ON  [dbo].[arvalpyt] TO [public]
GO
GRANT DELETE ON  [dbo].[arvalpyt] TO [public]
GO
GRANT UPDATE ON  [dbo].[arvalpyt] TO [public]
GO
