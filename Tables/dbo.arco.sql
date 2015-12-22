CREATE TABLE [dbo].[arco]
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
[days_before_purge] [smallint] NOT NULL,
[batch_proc_flag] [smallint] NOT NULL,
[ctrl_totals_flag] [smallint] NOT NULL,
[batch_usr_flag] [smallint] NOT NULL,
[gl_flag] [smallint] NOT NULL,
[iv_flag] [smallint] NOT NULL,
[ap_flag] [smallint] NOT NULL,
[pr_flag] [smallint] NOT NULL,
[bb_flag] [smallint] NOT NULL,
[oe_flag] [smallint] NOT NULL,
[default_rev_flag] [smallint] NOT NULL,
[default_tax_type] [smallint] NOT NULL,
[age_bracket1] [smallint] NOT NULL,
[age_bracket2] [smallint] NOT NULL,
[age_bracket3] [smallint] NOT NULL,
[age_bracket4] [smallint] NOT NULL,
[age_bracket5] [smallint] NOT NULL,
[max_wr_off_cash] [float] NOT NULL,
[max_wr_off_scrn] [float] NOT NULL,
[max_wr_off_proc] [float] NOT NULL,
[wr_off_days] [smallint] NOT NULL,
[date_range_verify] [int] NOT NULL,
[qty_error_flag] [smallint] NOT NULL,
[pricing_type] [smallint] NOT NULL,
[commission_flag] [smallint] NOT NULL,
[on_acct_flag] [smallint] NOT NULL,
[aractcus_flag] [smallint] NOT NULL,
[aractprc_flag] [smallint] NOT NULL,
[aractshp_flag] [smallint] NOT NULL,
[aractslp_flag] [smallint] NOT NULL,
[aractter_flag] [smallint] NOT NULL,
[arsumcus_flag] [smallint] NOT NULL,
[arsumprc_flag] [smallint] NOT NULL,
[arsumshp_flag] [smallint] NOT NULL,
[arsumslp_flag] [smallint] NOT NULL,
[arsumter_flag] [smallint] NOT NULL,
[invoice_copies] [smallint] NOT NULL,
[period_end_date] [int] NOT NULL,
[min_profit_type] [smallint] NOT NULL,
[tax_preference_flag] [smallint] NOT NULL,
[payer_soldto_rel_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[credit_check_rel_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[report_rel_code] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[across_na_flag] [smallint] NOT NULL,
[added_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[added_by_date] [datetime] NULL,
[modified_by_user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by_date] [datetime] NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mc_flag] [smallint] NULL,
[def_curr_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zero_inv_print] [smallint] NOT NULL,
[template_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[setup] [smallint] NOT NULL,
[VAT_report] [smallint] NOT NULL,
[arfinandunn_flag] [smallint] NOT NULL,
[authorize_onsave] [smallint] NULL,
[tax_connect_flag] [smallint] NULL CONSTRAINT [DF__arco__tax_connec__4DDF9D7F] DEFAULT ((0)),
[chargeback_flag] [smallint] NOT NULL,
[Invoice_Range_Flag] [smallint] NOT NULL CONSTRAINT [DF__arco__Invoice_Ra__417C289F] DEFAULT ((0))
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arco_ind_0] ON [dbo].[arco] ([company_name]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[arco] TO [public]
GO
GRANT SELECT ON  [dbo].[arco] TO [public]
GO
GRANT INSERT ON  [dbo].[arco] TO [public]
GO
GRANT DELETE ON  [dbo].[arco] TO [public]
GO
GRANT UPDATE ON  [dbo].[arco] TO [public]
GO
