CREATE TABLE [dbo].[cvo_appt_notes]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[appt_id] [smallint] NULL,
[appt_result] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[note_date] [datetime] NULL,
[appt_user] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[isAppointment] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_appt_notes] ADD CONSTRAINT [PK__cvo_appt_notes__07868B76] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
