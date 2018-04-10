CREATE TABLE [dbo].[cvo_whoisactive_log]
(
[dd hh:mm:ss.mss] [varchar] (8000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[session_id] [smallint] NULL,
[sql_text] [xml] NULL,
[login_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[wait_info] [nvarchar] (4000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[CPU] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tempdb_allocations] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[tempdb_current] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[blocking_session_id] [smallint] NULL,
[reads] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[writes] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[physical_reads] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[used_memory] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[status] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[open_tran_count] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[percent_complete] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[host_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[database_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[program_name] [nvarchar] (128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[start_time] [datetime] NULL,
[login_time] [datetime] NULL,
[request_id] [int] NULL,
[collection_time] [datetime] NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [dbo].[cvo_whoisactive_log] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_whoisactive_log] TO [public]
GO
GRANT REFERENCES ON  [dbo].[cvo_whoisactive_log] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_whoisactive_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_whoisactive_log] TO [public]
GO
