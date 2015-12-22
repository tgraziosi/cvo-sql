CREATE TYPE [dbo].[smErrorLevel] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smErrorLevel] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smErrorLevel_rl]', N'[dbo].[smErrorLevel]'
GO
EXEC sp_bindefault N'[dbo].[smErrorLevel_df]', N'[dbo].[smErrorLevel]'
GO
