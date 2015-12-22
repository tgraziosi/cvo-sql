CREATE TABLE [dbo].[cvo_surveys_responses_data]
(
[survey_id] [bigint] NULL,
[respondent_id] [bigint] NULL,
[response_ip] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_date] [datetime] NULL,
[q_id] [bigint] NULL,
[a_id] [bigint] NULL,
[a_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
