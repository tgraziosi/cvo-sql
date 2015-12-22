CREATE TABLE [dbo].[cvo_cmi_activity_log]
(
[brand] [char] (24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity] [text] COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[activity_date] [datetime] NULL,
[activity_user] [varchar] (16) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[model_id] [int] NULL,
[variant_id] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
