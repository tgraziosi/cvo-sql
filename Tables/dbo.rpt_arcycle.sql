CREATE TABLE [dbo].[rpt_arcycle]
(
[timestamp] [timestamp] NOT NULL,
[cycle_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cycle_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_used] [datetime] NULL,
[date_cancel] [datetime] NULL,
[cancel_flag_string] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_base] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_type_string] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_from] [datetime] NULL,
[tracked_flag_string] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[amt_tracked_balance] [float] NOT NULL,
[use_type] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[multi_currency_flag] [smallint] NOT NULL,
[symbol] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[curr_precision] [smallint] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcycle] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcycle] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcycle] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcycle] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcycle] TO [public]
GO
