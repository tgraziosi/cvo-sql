CREATE TABLE [dbo].[help_control]
(
[timestamp] [timestamp] NOT NULL,
[control_id] [varchar] (75) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[help_id] [int] NOT NULL,
[help_note] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[control_title] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[help_topic_id] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[doc_status] [char] (1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_by] [varchar] (4) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[modified_date] [datetime] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [help_control_pk] ON [dbo].[help_control] ([control_id]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[help_control] TO [public]
GO
GRANT SELECT ON  [dbo].[help_control] TO [public]
GO
GRANT INSERT ON  [dbo].[help_control] TO [public]
GO
GRANT DELETE ON  [dbo].[help_control] TO [public]
GO
GRANT UPDATE ON  [dbo].[help_control] TO [public]
GO
