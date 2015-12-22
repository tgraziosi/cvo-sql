CREATE TYPE [dbo].[smFilename] FROM char (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smFilename] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smFilename]'
GO
