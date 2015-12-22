CREATE TYPE [dbo].[smPostingMethod] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPostingMethod] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smPostingMethod_rl]', N'[dbo].[smPostingMethod]'
GO
EXEC sp_bindefault N'[dbo].[smPostingMethod_df]', N'[dbo].[smPostingMethod]'
GO
