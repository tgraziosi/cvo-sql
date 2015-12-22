CREATE TABLE [dbo].[cmco]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [smallint] NOT NULL,
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr1] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr2] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr3] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr4] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr5] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[company_str_addr6] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name1] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name2] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[addr_sort_name3] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[days_before_purge] [smallint] NOT NULL,
[batch_proc_flag] [smallint] NOT NULL,
[ctrl_totals_flag] [smallint] NOT NULL,
[batch_usr_flag] [smallint] NOT NULL,
[gl_flag] [smallint] NOT NULL,
[period_end_date] [int] NOT NULL,
[date_range_verify] [int] NOT NULL,
[company_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mc_flag] [smallint] NOT NULL,
[clearing_acct] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_home] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate_type_oper] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[setup] [smallint] NOT NULL,
[gl_post_flag] [smallint] NOT NULL,
[format_amount] [int] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cmco_ind_0] ON [dbo].[cmco] ([company_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cmco] TO [public]
GO
GRANT SELECT ON  [dbo].[cmco] TO [public]
GO
GRANT INSERT ON  [dbo].[cmco] TO [public]
GO
GRANT DELETE ON  [dbo].[cmco] TO [public]
GO
GRANT UPDATE ON  [dbo].[cmco] TO [public]
GO
