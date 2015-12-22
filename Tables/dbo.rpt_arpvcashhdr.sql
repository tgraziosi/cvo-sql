CREATE TABLE [dbo].[rpt_arpvcashhdr]
(
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[customer_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[doc_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_entered] [int] NOT NULL,
[date_posted] [int] NOT NULL,
[date_applied] [int] NOT NULL,
[gl_trx_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [smallint] NOT NULL,
[non_ar_doc_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[non_ar_flag] [smallint] NOT NULL,
[date_doc] [int] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_net] [float] NOT NULL,
[payment_type] [smallint] NOT NULL,
[prompt1_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_inp] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deposit_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void_flag] [smallint] NOT NULL,
[amt_on_acct] [float] NOT NULL,
[amt_discount] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_home] [float] NOT NULL,
[rate_oper] [float] NOT NULL,
[prompt1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt1_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt2_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt3_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[prompt4_mask_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_type] [smallint] NOT NULL,
[symbol] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpvcashhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpvcashhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpvcashhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpvcashhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpvcashhdr] TO [public]
GO
