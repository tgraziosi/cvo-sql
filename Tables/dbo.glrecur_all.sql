CREATE TABLE [dbo].[glrecur_all]
(
[timestamp] [timestamp] NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recur_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tracked_balance_flag] [smallint] NOT NULL,
[percentage_flag] [smallint] NOT NULL,
[continuous_flag] [smallint] NOT NULL,
[year_end_type] [smallint] NOT NULL,
[recur_if_zero_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[tracked_balance_amount] [float] NOT NULL,
[base_amount] [float] NOT NULL,
[date_last_applied] [int] NOT NULL,
[date_end_period_1] [int] NOT NULL,
[date_end_period_2] [int] NOT NULL,
[date_end_period_3] [int] NOT NULL,
[date_end_period_4] [int] NOT NULL,
[date_end_period_5] [int] NOT NULL,
[date_end_period_6] [int] NOT NULL,
[date_end_period_7] [int] NOT NULL,
[date_end_period_8] [int] NOT NULL,
[date_end_period_9] [int] NOT NULL,
[date_end_period_10] [int] NOT NULL,
[date_end_period_11] [int] NOT NULL,
[date_end_period_12] [int] NOT NULL,
[date_end_period_13] [int] NOT NULL,
[all_periods] [smallint] NOT NULL,
[number_of_periods] [smallint] NOT NULL,
[period_interval] [smallint] NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[interbranch_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glrecur_all_ind_0] ON [dbo].[glrecur_all] ([journal_ctrl_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glrecur_all] TO [public]
GO
GRANT SELECT ON  [dbo].[glrecur_all] TO [public]
GO
GRANT INSERT ON  [dbo].[glrecur_all] TO [public]
GO
GRANT DELETE ON  [dbo].[glrecur_all] TO [public]
GO
GRANT UPDATE ON  [dbo].[glrecur_all] TO [public]
GO
