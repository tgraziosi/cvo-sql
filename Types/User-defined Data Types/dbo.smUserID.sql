CREATE TYPE [dbo].[smUserID] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smUserID] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smUserID]'
GO
