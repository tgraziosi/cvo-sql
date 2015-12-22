CREATE TYPE [dbo].[smSurrogateKey] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smSurrogateKey] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smSurrogateKey]'
GO
