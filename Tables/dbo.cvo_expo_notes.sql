CREATE TABLE [dbo].[cvo_expo_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[expo_id] [tinyint] NULL,
[category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_date] [datetime] NULL,
[appt_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isAppointment] [tinyint] NULL,
[flag] [tinyint] NULL CONSTRAINT [DF__cvo_expo_n__flag__67B90C2C] DEFAULT ((1)),
[appt_id] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_expo_notes] ADD CONSTRAINT [PK__cvo_expo_notes__66C4E7F3] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
