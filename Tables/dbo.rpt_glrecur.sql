CREATE TABLE [dbo].[rpt_glrecur]
(
[timestamp] [timestamp] NOT NULL,
[group1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[group2] [datetime] NOT NULL,
[group3] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[recur_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[tracked_balance_flag] [smallint] NOT NULL,
[percentage_flag] [smallint] NOT NULL,
[continuous_flag] [smallint] NOT NULL,
[year_end_type] [smallint] NOT NULL,
[recur_if_zero_flag] [smallint] NOT NULL,
[hold_flag] [smallint] NOT NULL,
[tracked_balance_amount] [float] NOT NULL,
[base_amount] [float] NOT NULL,
[date_last_applied] [int] NOT NULL,
[intercompany_flag] [smallint] NOT NULL,
[number_of_periods] [smallint] NOT NULL,
[posted_flag] [smallint] NOT NULL,
[document_1] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[nat_curr_precision] [smallint] NOT NULL,
[nat_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[org_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[region_id] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glrecur] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glrecur] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glrecur] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glrecur] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glrecur] TO [public]
GO
