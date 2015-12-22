CREATE TABLE [dbo].[rpt_ammassmt]
(
[mass_maintenance_id] [int] NOT NULL,
[mass_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[one_at_a_time] [tinyint] NOT NULL,
[assets_purged] [tinyint] NOT NULL,
[process_start_date] [datetime] NOT NULL,
[process_end_date] [datetime] NOT NULL,
[error_message] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[classification_id] [int] NOT NULL,
[classification_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[mass_maintenance_type] [int] NOT NULL,
[field_type] [int] NOT NULL,
[new_value] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_ammassmt] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_ammassmt] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_ammassmt] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_ammassmt] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_ammassmt] TO [public]
GO
