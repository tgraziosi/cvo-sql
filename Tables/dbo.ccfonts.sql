CREATE TABLE [dbo].[ccfonts]
(
[font_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[font_size] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[font_bold] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[font_italics] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[user_id] [int] NOT NULL CONSTRAINT [DF__ccfonts__user_id__2475D59D] DEFAULT ((0))
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[ccfonts] TO [public]
GO
GRANT SELECT ON  [dbo].[ccfonts] TO [public]
GO
GRANT INSERT ON  [dbo].[ccfonts] TO [public]
GO
GRANT DELETE ON  [dbo].[ccfonts] TO [public]
GO
GRANT UPDATE ON  [dbo].[ccfonts] TO [public]
GO
