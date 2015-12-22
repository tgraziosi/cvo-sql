CREATE TABLE [dbo].[arcusmerpctrl]
(
[entry_date] [timestamp] NOT NULL,
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[target_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trial_flag] [int] NOT NULL,
[on_order] [float] NOT NULL,
[unposted] [float] NOT NULL,
[posted_count] [int] NOT NULL,
[paid_count] [int] NOT NULL,
[overdue_count] [int] NOT NULL,
[bucket1] [float] NOT NULL,
[bucket2] [float] NOT NULL,
[bucket3] [float] NOT NULL,
[bucket4] [float] NOT NULL,
[bucket5] [float] NOT NULL,
[bucket6] [float] NOT NULL,
[on_account] [float] NOT NULL,
[balance] [float] NOT NULL,
[username] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_executed] [datetime] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [arcusmerpctrl_0] ON [dbo].[arcusmerpctrl] ([process_ctrl_num]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[arcusmerpctrl] TO [public]
GO
GRANT INSERT ON  [dbo].[arcusmerpctrl] TO [public]
GO
GRANT DELETE ON  [dbo].[arcusmerpctrl] TO [public]
GO
GRANT UPDATE ON  [dbo].[arcusmerpctrl] TO [public]
GO
