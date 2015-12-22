CREATE TABLE [dbo].[cvo_AutoEmails]
(
[ae_id] [int] NOT NULL IDENTITY(1, 1),
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[subject_line] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[body_text] [varchar] (3000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[attachment] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[date_created] [datetime] NULL,
[date_sent] [datetime] NULL,
[processed] [smallint] NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cvo_AutoEmails] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_AutoEmails] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_AutoEmails] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_AutoEmails] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_AutoEmails] TO [public]
GO
