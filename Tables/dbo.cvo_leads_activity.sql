CREATE TABLE [dbo].[cvo_leads_activity]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[lead_id] [int] NULL,
[activity_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL,
[activity] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_leads_activity] ADD CONSTRAINT [PK__cvo_leads_activi__2A73025C] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
