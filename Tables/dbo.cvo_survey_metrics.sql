CREATE TABLE [dbo].[cvo_survey_metrics]
(
[cust_code] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[survey_id] [bigint] NULL,
[respondent_id] [bigint] NULL,
[q_id] [bigint] NULL,
[q_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[a_id] [int] NULL,
[a_option_id] [bigint] NULL,
[a_text] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[q_weight] [int] NULL,
[survey_ip] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
