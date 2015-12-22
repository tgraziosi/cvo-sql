CREATE TABLE [dbo].[cvo_cmi_users]
(
[fname] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lname] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[dept] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[title] [varchar] (80) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[email] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manager] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[userid] [smallint] NOT NULL IDENTITY(1, 1),
[user_login] [varchar] (40) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[detail] [varchar] (max) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[cvo_cmi_users] ADD CONSTRAINT [PK__cvo_cmi_users__72C43FA3] PRIMARY KEY CLUSTERED  ([userid]) ON [PRIMARY]
GO
