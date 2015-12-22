CREATE TABLE [dbo].[glnofind]
(
[timestamp] [timestamp] NOT NULL,
[sequence_id] [int] NOT NULL,
[nonfin_budget_code] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[period_end_date] [int] NOT NULL,
[account_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[unit_of_measure] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[quantity] [float] NOT NULL,
[ytd_quantity] [float] NOT NULL,
[seg1_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg2_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg3_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[seg4_code] [varchar] (32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[changed_flag] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [glnofind_ind_0] ON [dbo].[glnofind] ([nonfin_budget_code], [period_end_date], [account_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[glnofind] TO [public]
GO
GRANT SELECT ON  [dbo].[glnofind] TO [public]
GO
GRANT INSERT ON  [dbo].[glnofind] TO [public]
GO
GRANT DELETE ON  [dbo].[glnofind] TO [public]
GO
GRANT UPDATE ON  [dbo].[glnofind] TO [public]
GO
