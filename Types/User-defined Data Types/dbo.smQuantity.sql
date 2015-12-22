CREATE TYPE [dbo].[smQuantity] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smQuantity] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[smQuantity]'
GO
