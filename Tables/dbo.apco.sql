CREATE TABLE [dbo].[apco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posting_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[one_time_vend_code] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_before_purge] [smallint] NOT NULL,
[batch_proc_flag] [smallint] NOT NULL,
[ctrl_totals_flag] [smallint] NOT NULL,
[batch_usr_flag] [smallint] NOT NULL,
[basis_flag] [smallint] NOT NULL,
[check_print_flag] [smallint] NOT NULL,
[tax_id_num] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aprv_po_flag] [smallint] NOT NULL,
[aprv_voucher_flag] [smallint] NOT NULL,
[aprv_check_flag] [smallint] NOT NULL,
[default_aprv_flag] [smallint] NOT NULL,
[aprv_opr_flag] [smallint] NOT NULL,
[default_aprv_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_flag] [smallint] NOT NULL,
[iv_flag] [smallint] NOT NULL,
[ar_flag] [smallint] NOT NULL,
[pr_flag] [smallint] NOT NULL,
[bb_flag] [smallint] NOT NULL,
[po_flag] [smallint] NOT NULL,
[jc_flag] [smallint] NOT NULL,
[default_tax_type] [smallint] NOT NULL,
[age_bracket1] [smallint] NOT NULL,
[age_bracket2] [smallint] NOT NULL,
[age_bracket3] [smallint] NOT NULL,
[age_bracket4] [smallint] NOT NULL,
[age_bracket5] [smallint] NOT NULL,
[apactvnd_flag] [smallint] NOT NULL,
[apactpto_flag] [smallint] NOT NULL,
[apactcls_flag] [smallint] NOT NULL,
[apactbch_flag] [smallint] NOT NULL,
[apsumvnd_flag] [smallint] NOT NULL,
[apsumpto_flag] [smallint] NOT NULL,
[apsumcls_flag] [smallint] NOT NULL,
[apsumbch_flag] [smallint] NOT NULL,
[apsumvi_flag] [smallint] NOT NULL,
[date_range_verify] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[default_cash_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[terms_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tax_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[aprv_voucher_det_flag] [smallint] NOT NULL,
[user_trx_type_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[direct_pyt_post_flag] [smallint] NOT NULL,
[payment_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[gl_desc_def] [smallint] NOT NULL,
[tax_preference_flag] [smallint] NULL,
[default_exp_flag] [smallint] NULL,
[sds_iv_flag] [smallint] NOT NULL,
[intercompany_flag] [smallint] NULL,
[currency_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mc_flag] [smallint] NULL,
[am_flag] [smallint] NULL,
[aprv_hm_flag] [smallint] NULL,
[setup] [smallint] NOT NULL,
[credit_invoice_flag] [smallint] NOT NULL,
[check_prnt_flag] [smallint] NOT NULL,
[default_apply_date_flag] [smallint] NULL,
[proc_flag] [smallint] NULL,
[expense_tax_override_flag] [int] NOT NULL,
[amount_over] [float] NOT NULL,
[amount_under] [float] NOT NULL,
[percent_over] [float] NOT NULL,
[percent_under] [float] NOT NULL,
[tax_connect_flag] [smallint] NULL CONSTRAINT [DF__apco__tax_connec__28E257A3] DEFAULT ((0)),
[batch_desc_flag] [smallint] NULL CONSTRAINT [DF__apco__batch_desc__29D67BDC] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apco_ind_0] ON [dbo].[apco] ([company_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apco] TO [public]
GO
GRANT SELECT ON  [dbo].[apco] TO [public]
GO
GRANT INSERT ON  [dbo].[apco] TO [public]
GO
GRANT DELETE ON  [dbo].[apco] TO [public]
GO
GRANT UPDATE ON  [dbo].[apco] TO [public]
GO
