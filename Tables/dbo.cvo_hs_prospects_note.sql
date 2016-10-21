CREATE TABLE [dbo].[cvo_hs_prospects_note]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[hs_cust_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_date] [datetime] NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[hs_obj_id] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_hs_prospects_note] ADD CONSTRAINT [PK__cvo_hs_prospects__077C9B9F] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
