CREATE TABLE [dbo].[cvo_podcast_videos]
(
[id] [smallint] NOT NULL IDENTITY(1, 1),
[title] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_author] [varchar] (60) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_subtitle] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_summary] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[enclosure_url] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_duration] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_keywords] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[pubDate] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[itunes_explicit] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL CONSTRAINT [DF__cvo_podca__itune__717BE106] DEFAULT ('no')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_podcast_videos] ADD CONSTRAINT [PK__cvo_podcast_vide__7087BCCD] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
