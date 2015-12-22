CREATE TYPE [dbo].[smCounter] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCounter] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smCounter]'
GO
