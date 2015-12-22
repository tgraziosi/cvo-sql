CREATE TABLE [dbo].[cvo_survey_responses_summary]
(
[survey_id] [bigint] NULL,
[respondent_id] [bigint] NULL,
[response_ip] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_date] [datetime] NULL,
[survey_url] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[grading] [smallint] NULL CONSTRAINT [DF__cvo_surve__gradi__2219BACA] DEFAULT ('0')
) ON [PRIMARY]
GO
