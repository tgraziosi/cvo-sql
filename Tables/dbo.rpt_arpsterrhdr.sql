CREATE TABLE [dbo].[rpt_arpsterrhdr]
(
[process_parent_app] [smallint] NOT NULL,
[process_parent_company] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_description] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_user_id] [smallint] NOT NULL,
[process_server_id] [int] NOT NULL,
[process_host_id] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[process_kpid] [int] NOT NULL,
[process_start_date] [int] NOT NULL,
[process_end_date] [int] NOT NULL,
[process_start_time] [int] NOT NULL,
[process_end_time] [int] NOT NULL,
[process_state] [smallint] NOT NULL,
[process_status] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[process_type] [smallint] NOT NULL,
[user_name] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[batch_ctrl_num] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[start_number] [int] NOT NULL,
[start_total] [float] NOT NULL,
[end_number] [int] NOT NULL,
[end_total] [float] NOT NULL,
[process_start_date1] [int] NOT NULL,
[process_end_date1] [int] NOT NULL,
[process_start_time1] [int] NOT NULL,
[process_end_time1] [int] NOT NULL,
[flag] [smallint] NOT NULL,
[process_ctrl_num] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[trx_ctrl_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sequence_id] [smallint] NOT NULL,
[err_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[deposit_num] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[rpt_arpsterrhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[rpt_arpsterrhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[rpt_arpsterrhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[rpt_arpsterrhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[rpt_arpsterrhdr] TO [public]
GO
