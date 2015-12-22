CREATE TABLE [dbo].[cvo_survey_header]
(
[survey_id] [bigint] NULL,
[q_id] [bigint] NULL,
[q_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[q_weight] [int] NULL,
[a_id] [bigint] NULL,
[a_label] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
