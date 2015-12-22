CREATE TABLE [dbo].[cc_alert_defaults]
(
[number_days] [int] NOT NULL,
[date_type] [smallint] NOT NULL,
[create_fu] [smallint] NOT NULL,
[create_reminder] [smallint] NOT NULL,
[recurring] [smallint] NOT NULL,
[user_id] [int] NOT NULL,
[all_workloads] [smallint] NOT NULL,
[workload_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[auto_run] [smallint] NOT NULL,
[disable_options] [smallint] NOT NULL,
[create_comment] [smallint] NULL,
[invoice_status_flag] [smallint] NULL,
[customer_status_flag] [smallint] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [cc_alert_defaults_idx1] ON [dbo].[cc_alert_defaults] ([user_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_alert_defaults] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_alert_defaults] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_alert_defaults] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_alert_defaults] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_alert_defaults] TO [public]
GO
