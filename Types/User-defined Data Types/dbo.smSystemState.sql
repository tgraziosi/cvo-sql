CREATE TYPE [dbo].[smSystemState] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smSystemState] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smSystemState_rl]', N'[dbo].[smSystemState]'
GO
EXEC sp_bindefault N'[dbo].[smSystemState_df]', N'[dbo].[smSystemState]'
GO
