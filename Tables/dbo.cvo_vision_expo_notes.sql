CREATE TABLE [dbo].[cvo_vision_expo_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[appt_id] [int] NULL,
[expo_id] [tinyint] NULL,
[category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_date] [datetime] NULL,
[appt_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isAppointment] [tinyint] NULL,
[flag] [tinyint] NULL CONSTRAINT [DF__cvo_vision__flag__7F03587C] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_vision_expo_notes] ADD CONSTRAINT [PK__cvo_vision_expo___09EAFB43] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
