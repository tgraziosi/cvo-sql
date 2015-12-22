CREATE TYPE [dbo].[smErrorActive] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smErrorActive] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smErrorActive_rl]', N'[dbo].[smErrorActive]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[smErrorActive]'
GO
