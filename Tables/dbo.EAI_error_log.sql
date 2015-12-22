CREATE TABLE [dbo].[EAI_error_log]
(
[error_key] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[dead_letter_id] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[bus_doc_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[message_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EAI_error_log_message_type] DEFAULT ('P'),
[primary_keys] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_no] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_location] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[error_desc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[error_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EAI_error_log_error_status] DEFAULT ('N'),
[error_date] [datetime] NOT NULL CONSTRAINT [DF_EAI_error_log_error_date] DEFAULT (getdate()),
[error_type] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EAI_error_log_error_type] DEFAULT ('B'),
[notes] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[EAI_error_log] WITH NOCHECK ADD CONSTRAINT [CK_EAI_error_log] CHECK ((([message_type]='T' OR [message_type]='P') AND ([error_status]='C' OR [error_status]='R' OR [error_status]='N') AND ([error_type]='S' OR [error_type]='B')))
GO
ALTER TABLE [dbo].[EAI_error_log] ADD CONSTRAINT [PK_EAI_error_log] PRIMARY KEY NONCLUSTERED  ([error_key]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[EAI_error_log] TO [public]
GO
GRANT SELECT ON  [dbo].[EAI_error_log] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_error_log] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_error_log] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_error_log] TO [public]
GO
