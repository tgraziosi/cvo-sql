CREATE TYPE [dbo].[smRate] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smRate] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smRate]'
GO
