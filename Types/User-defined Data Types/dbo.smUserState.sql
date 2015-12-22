CREATE TYPE [dbo].[smUserState] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smUserState] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smUserState_rl]', N'[dbo].[smUserState]'
GO
EXEC sp_bindefault N'[dbo].[smUserState_df]', N'[dbo].[smUserState]'
GO
