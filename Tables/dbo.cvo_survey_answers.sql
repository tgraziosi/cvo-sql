CREATE TABLE [dbo].[cvo_survey_answers]
(
[survey_id] [bigint] NULL,
[q_id] [bigint] NULL,
[a_id] [bigint] NULL,
[a_text] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_weight] [int] NULL,
[a_type] [char] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
