CREATE TYPE [dbo].[smTrxSource] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smTrxSource] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smTrxSource_rl]', N'[dbo].[smTrxSource]'
GO
EXEC sp_bindefault N'[dbo].[smTrxSource_df]', N'[dbo].[smTrxSource]'
GO
