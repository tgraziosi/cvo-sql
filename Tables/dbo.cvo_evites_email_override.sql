CREATE TABLE [dbo].[cvo_evites_email_override]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[account_no] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[ship_to] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[user_id] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[override_date] [datetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_evites_email_override] ADD CONSTRAINT [PK__cvo_evites_email__17612B09] PRIMARY KEY CLUSTERED  ([id]) ON [PRIMARY]
GO
