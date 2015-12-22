CREATE TABLE [dbo].[SSI_USR]
(
[USERID] [int] NOT NULL,
[DBLOGIN] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[USERNOTE] [varchar] (255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_USR] ADD CONSTRAINT [PK__SSI_USR__44988C6C] PRIMARY KEY CLUSTERED  ([USERID]) ON [PRIMARY]
GO
GRANT SELECT ON  [dbo].[SSI_USR] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_USR] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_USR] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_USR] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_USR] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_USR] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_USR] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_USR] TO [public]
GO
