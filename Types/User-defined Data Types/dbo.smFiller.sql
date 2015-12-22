CREATE TYPE [dbo].[smFiller] FROM char (255) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smFiller] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smFiller]'
GO
