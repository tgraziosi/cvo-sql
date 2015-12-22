CREATE TABLE [dbo].[rpt_arcusmerlog]
(
[process_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[target_customer] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trial_flag] [smallint] NOT NULL,
[log_text] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[username] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date_executed] [datetime] NOT NULL,
[target_name] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arcusmerlog] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arcusmerlog] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arcusmerlog] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arcusmerlog] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arcusmerlog] TO [public]
GO
