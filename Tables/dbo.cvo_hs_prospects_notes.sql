CREATE TABLE [dbo].[cvo_hs_prospects_notes]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[hs_cust_id] [varchar] (12) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[notes_date] [datetime] NULL,
[notes] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_hs_prospects_notes] ADD CONSTRAINT [PK__cvo_hs_prospects__13228D1E] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
