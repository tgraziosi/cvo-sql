CREATE TABLE [dbo].[cvo_mido_online_appointments]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[fname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[company] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[phone] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[zipcode] [varchar] (15) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[country] [varchar] (120) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_mido_online_appointments] ADD CONSTRAINT [PK__cvo_mido_online___43250F4D] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
