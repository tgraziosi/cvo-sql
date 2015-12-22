CREATE TYPE [dbo].[smDocumentReference] FROM varchar (40) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smDocumentReference] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smDocumentReference]'
GO
