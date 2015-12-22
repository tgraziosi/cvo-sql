CREATE TABLE [dbo].[adm_message]
(
[timestamp] [timestamp] NOT NULL,
[message_id] [uniqueidentifier] NOT NULL,
[message_instance_id] [uniqueidentifier] NOT NULL,
[message_dt] [datetime] NOT NULL,
[email_template_nm] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[email_type] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[from_user] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[sent_ind] [int] NOT NULL,
[subject] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[link_tx] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[width] [int] NULL,
[no_header] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attach_results] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[remind_dt] [datetime] NULL,
[expire_dt] [datetime] NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [message_t3] ON [dbo].[adm_message] ([expire_dt], [message_id]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [message_t1] ON [dbo].[adm_message] ([message_id]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [message_t2] ON [dbo].[adm_message] ([message_instance_id], [sent_ind], [remind_dt]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [message_t4] ON [dbo].[adm_message] ([sent_ind], [email_type], [remind_dt]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[adm_message] TO [public]
GO
GRANT SELECT ON  [dbo].[adm_message] TO [public]
GO
GRANT INSERT ON  [dbo].[adm_message] TO [public]
GO
GRANT DELETE ON  [dbo].[adm_message] TO [public]
GO
GRANT UPDATE ON  [dbo].[adm_message] TO [public]
GO
