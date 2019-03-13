CREATE TABLE [dbo].[cvo_sc_route_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[prospect_id] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[visit_date] [datetime] NULL,
[notes_category] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[appt_start] [datetime] NULL,
[appt_end] [datetime] NULL,
[appt_location] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_sc_route_notes] ADD CONSTRAINT [PK__cvo_sc_route_not__45B2059E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
