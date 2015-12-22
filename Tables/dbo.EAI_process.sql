CREATE TABLE [dbo].[EAI_process]
(
[key_id] [numeric] (18, 0) NOT NULL IDENTITY(1, 1),
[vb_script] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[data] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[source_platform] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[action] [int] NOT NULL CONSTRAINT [DF_EAI_process_action] DEFAULT ((0)),
[entered_time] [datetime] NOT NULL CONSTRAINT [DF_EAI_process_entered_time] DEFAULT (getdate()),
[deleted_flag] [varchar] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL CONSTRAINT [DF_EAI_process_deleted_flag] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [EAI_Process_Ind1] ON [dbo].[EAI_process] ([vb_script], [data], [source_platform], [action]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[EAI_process] TO [public]
GO
GRANT INSERT ON  [dbo].[EAI_process] TO [public]
GO
GRANT DELETE ON  [dbo].[EAI_process] TO [public]
GO
GRANT UPDATE ON  [dbo].[EAI_process] TO [public]
GO
