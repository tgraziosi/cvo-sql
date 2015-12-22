CREATE TYPE [dbo].[smMonth] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smMonth] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smMonth_rl]', N'[dbo].[smMonth]'
GO
EXEC sp_bindefault N'[dbo].[smMonth_df]', N'[dbo].[smMonth]'
GO
