CREATE TYPE [dbo].[smRemainingLife] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smRemainingLife] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smRemainingLife]'
GO
