CREATE TABLE [dbo].[apcycle]
(
[timestamp] [timestamp] NOT NULL,
[cycle_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[cycle_desc] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_last_used] [int] NOT NULL,
[date_from] [int] NOT NULL,
[cycle_type] [smallint] NOT NULL,
[number] [smallint] NOT NULL,
[cancel_flag] [smallint] NOT NULL,
[date_cancel] [int] NOT NULL,
[amt_base] [float] NOT NULL,
[tracked_flag] [smallint] NOT NULL,
[amt_tracked_balance] [float] NOT NULL,
[nat_cur_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[on_hold] [smallint] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [apcycle_ind_0] ON [dbo].[apcycle] ([cycle_code]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[apcycle] TO [public]
GO
GRANT SELECT ON  [dbo].[apcycle] TO [public]
GO
GRANT INSERT ON  [dbo].[apcycle] TO [public]
GO
GRANT DELETE ON  [dbo].[apcycle] TO [public]
GO
GRANT UPDATE ON  [dbo].[apcycle] TO [public]
GO
