CREATE TYPE [dbo].[smPostingState] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPostingState] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[smPostingState]'
GO
