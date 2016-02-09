CREATE TABLE [dbo].[cvo_seco_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[appt_id] [int] NULL,
[expo_id] [tinyint] NULL,
[category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_date] [datetime] NULL,
[appt_user] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isAppointment] [tinyint] NULL,
[flag] [tinyint] NULL CONSTRAINT [DF__cvo_seco_n__flag__661945CF] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_seco_notes] ADD CONSTRAINT [PK__cvo_seco_notes__65252196] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
