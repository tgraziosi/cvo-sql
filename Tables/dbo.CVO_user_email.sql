CREATE TABLE [dbo].[CVO_user_email]
(
[userid] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email_address] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [CVO_user_email_ind0] ON [dbo].[CVO_user_email] ([userid]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[CVO_user_email] TO [public]
GO
GRANT SELECT ON  [dbo].[CVO_user_email] TO [public]
GO
GRANT INSERT ON  [dbo].[CVO_user_email] TO [public]
GO
GRANT DELETE ON  [dbo].[CVO_user_email] TO [public]
GO
GRANT UPDATE ON  [dbo].[CVO_user_email] TO [public]
GO
