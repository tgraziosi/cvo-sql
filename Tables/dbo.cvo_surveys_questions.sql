CREATE TABLE [dbo].[cvo_surveys_questions]
(
[survey_id] [bigint] NULL,
[q_id] [bigint] NULL,
[q_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[q_type] [char] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[count_option] [tinyint] NULL CONSTRAINT [DF__cvo_surve__count__26A33CCF] DEFAULT ((0)),
[response_divide] [tinyint] NULL CONSTRAINT [DF__cvo_surve__respo__297FA97A] DEFAULT ((1))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
