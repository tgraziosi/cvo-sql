CREATE TABLE [dbo].[cvo_survey_questions]
(
[survey_id] [bigint] NULL,
[q_id] [bigint] NULL,
[q_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[q_type] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
