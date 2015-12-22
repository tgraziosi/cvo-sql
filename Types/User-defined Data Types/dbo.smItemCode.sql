CREATE TYPE [dbo].[smItemCode] FROM varchar (22) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smItemCode] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smItemCode]'
GO
