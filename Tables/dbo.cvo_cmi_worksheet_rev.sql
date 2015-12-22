CREATE TABLE [dbo].[cvo_cmi_worksheet_rev]
(
[rev_id] [int] NOT NULL IDENTITY(1, 1),
[brand] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_id] [int] NULL,
[rev_date] [datetime] NULL,
[rev_note] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rev_file] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[rev_user] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_option] [varchar] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_to] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_cc] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_subject] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[mail_content] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_worksheet_rev] ADD CONSTRAINT [PK__cvo_cmi_workshee__58CA05DF] PRIMARY KEY CLUSTERED  ([rev_id]) ON [PRIMARY]
GO
