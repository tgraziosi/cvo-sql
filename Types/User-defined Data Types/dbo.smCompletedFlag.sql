CREATE TYPE [dbo].[smCompletedFlag] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCompletedFlag] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smCompletedFlag_rl]', N'[dbo].[smCompletedFlag]'
GO
EXEC sp_bindefault N'[dbo].[smCompletedFlag_df]', N'[dbo].[smCompletedFlag]'
GO
