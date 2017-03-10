CREATE TABLE [dbo].[cvo_model_survey_response]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[username] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[survey_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[data] [varchar] (5000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[datetime] [smalldatetime] NOT NULL CONSTRAINT [DF__cvo_model__datet__51373035] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_model_survey_response] ADD CONSTRAINT [PK__cvo_model_survey__50430BFC] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
