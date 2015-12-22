CREATE TABLE [dbo].[rpt_glconrec]
(
[timestamp] [timestamp] NOT NULL,
[consol_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_asof] [int] NOT NULL,
[period_start_date] [int] NOT NULL,
[period_end_date] [int] NOT NULL,
[period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sub_period_start_date] [int] NULL,
[sub_period_end_date] [int] NULL,
[sub_period_description] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_company] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_home_currency] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_home_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_home_curr_precision] [smallint] NULL,
[sub_oper_currency] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_oper_symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[sub_oper_curr_precision] [smallint] NULL,
[sub_account_format_mask] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[journal_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[journal_type] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[posted_flag] [smallint] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[db_name] [varchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[init_period] [int] NOT NULL,
[owner_percent] [float] NOT NULL,
[rate_mode] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_glconrec] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_glconrec] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_glconrec] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_glconrec] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_glconrec] TO [public]
GO
