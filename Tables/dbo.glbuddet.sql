CREATE TABLE [dbo].[glbuddet]
(
[timestamp] [timestamp] NOT NULL,
[sequence_id] [int] NOT NULL,
[budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[reference_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_glbuddet] DEFAULT (''),
[net_change] [float] NOT NULL,
[current_balance] [float] NOT NULL,
[period_end_date] [int] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[changed_flag] [smallint] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[rate] [float] NULL,
[rate_oper] [float] NULL,
[nat_net_change] [float] NULL,
[nat_current_balance] [float] NULL,
[net_change_oper] [float] NULL,
[current_balance_oper] [float] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [glbuddet_ind_0] ON [dbo].[glbuddet] ([budget_code], [period_end_date], [account_code], [reference_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glbuddet] TO [public]
GO
GRANT SELECT ON  [dbo].[glbuddet] TO [public]
GO
GRANT INSERT ON  [dbo].[glbuddet] TO [public]
GO
GRANT DELETE ON  [dbo].[glbuddet] TO [public]
GO
GRANT UPDATE ON  [dbo].[glbuddet] TO [public]
GO
