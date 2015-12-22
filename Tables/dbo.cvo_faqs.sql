CREATE TABLE [dbo].[cvo_faqs]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[category] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[question] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[whattosay] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[howto] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[exception] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_faqs] ADD CONSTRAINT [PK__cvo_faqs__2A7C58A6] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
