CREATE TYPE [dbo].[smStdDescription] FROM varchar (40) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smStdDescription] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smStdDescription]'
GO
