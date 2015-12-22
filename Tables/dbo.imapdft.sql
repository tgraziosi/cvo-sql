CREATE TABLE [dbo].[imapdft]
(
[status_type] [smallint] NOT NULL,
[fob_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[location_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[orig_zone_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[vend_class_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[branch_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[pay_to_hist_flag] [smallint] NOT NULL,
[item_hist_flag] [smallint] NOT NULL,
[credit_limit_flag] [smallint] NOT NULL,
[credit_limit] [float] NOT NULL,
[aging_limit_flag] [smallint] NOT NULL,
[aging_limit] [smallint] NOT NULL,
[restock_chg_flag] [smallint] NOT NULL,
[restock_chg] [float] NOT NULL,
[prc_flag] [smallint] NOT NULL,
[flag_1099] [smallint] NOT NULL,
[exp_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_max_check] [float] NOT NULL,
[lead_time] [smallint] NOT NULL,
[comment] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[one_check_flag] [smallint] NOT NULL,
[code_1099] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[limit_by_home] [smallint] NOT NULL,
[one_cur_vendor] [smallint] NOT NULL,
[cash_acct_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dup_voucher_flag] [smallint] NOT NULL,
[dup_amt_flag] [smallint] NOT NULL,
[freight_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[imapdft] TO [public]
GO
GRANT SELECT ON  [dbo].[imapdft] TO [public]
GO
GRANT INSERT ON  [dbo].[imapdft] TO [public]
GO
GRANT DELETE ON  [dbo].[imapdft] TO [public]
GO
GRANT UPDATE ON  [dbo].[imapdft] TO [public]
GO
