CREATE TYPE [dbo].[smTag] FROM char (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smTag] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smTag]'
GO
