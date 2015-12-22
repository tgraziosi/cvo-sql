CREATE TABLE [dbo].[in_account]
(
[timestamp] [timestamp] NOT NULL,
[acct_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sales_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_direct_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_ovhd_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[inv_util_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[raw_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[raw_direct_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[raw_ovhd_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[raw_util_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_increase] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_direct_increase] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_ovhd_increase] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_util_increase] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_decrease] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_direct_decrease] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_ovhd_decrease] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[std_adj_util_decrease] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[wip_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[wip_direct_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[wip_ovhd_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[wip_util_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_var_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_var_direct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_var_ovhd_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cost_var_util_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_cgs_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_cgs_direct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_cgs_ovhd_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_cgs_util_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_cgp_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_cgp_direct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_cgp_ovhd_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ap_cgp_util_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[transfer_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[spoilage_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[consignment_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[ar_cgs_mask] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[void] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__in_account__void__0486924A] DEFAULT ('N'),
[void_who] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF__in_accoun__void___057AB683] DEFAULT (' '),
[void_date] [datetime] NOT NULL CONSTRAINT [DF__in_accoun__void___066EDABC] DEFAULT ('1 / 1 / 1990'),
[rec_var_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sales_return_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[var_mat_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[var_direct_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[var_overh_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[var_utility_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[qc_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_mtrl_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_dir_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_ovhd_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[qc_util_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[in_account] ADD CONSTRAINT [PK_in_account_1__19] PRIMARY KEY CLUSTERED  ([acct_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[in_account] TO [public]
GO
GRANT SELECT ON  [dbo].[in_account] TO [public]
GO
GRANT INSERT ON  [dbo].[in_account] TO [public]
GO
GRANT DELETE ON  [dbo].[in_account] TO [public]
GO
GRANT UPDATE ON  [dbo].[in_account] TO [public]
GO
