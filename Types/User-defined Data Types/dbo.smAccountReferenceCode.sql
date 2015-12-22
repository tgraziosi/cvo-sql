CREATE TYPE [dbo].[smAccountReferenceCode] FROM varchar (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smAccountReferenceCode] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smAccountReferenceCode]'
GO
