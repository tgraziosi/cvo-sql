CREATE TABLE [dbo].[SSI_USP]
(
[USERID] [int] NOT NULL,
[FIELDENUM] [int] NOT NULL,
[FIELDNAME] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[FIELDVALUE] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[SSI_USP] ADD CONSTRAINT [FK__SSI_USP__USERID__4680D4DE] FOREIGN KEY ([USERID]) REFERENCES [dbo].[SSI_USR] ([USERID])
GO
GRANT SELECT ON  [dbo].[SSI_USP] TO [epicoradmin]
GO
GRANT INSERT ON  [dbo].[SSI_USP] TO [epicoradmin]
GO
GRANT DELETE ON  [dbo].[SSI_USP] TO [epicoradmin]
GO
GRANT UPDATE ON  [dbo].[SSI_USP] TO [epicoradmin]
GO
GRANT SELECT ON  [dbo].[SSI_USP] TO [public]
GO
GRANT INSERT ON  [dbo].[SSI_USP] TO [public]
GO
GRANT DELETE ON  [dbo].[SSI_USP] TO [public]
GO
GRANT UPDATE ON  [dbo].[SSI_USP] TO [public]
GO
