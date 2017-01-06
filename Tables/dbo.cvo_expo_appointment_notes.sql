CREATE TABLE [dbo].[cvo_expo_appointment_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [int] NULL,
[appt_id] [int] NULL,
[reason] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_date] [datetime] NULL CONSTRAINT [DF__cvo_expo___notes__1C8370D4] DEFAULT (getdate()),
[notes_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_appointment_notes] ADD CONSTRAINT [PK__cvo_expo_appoint__1B8F4C9B] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
