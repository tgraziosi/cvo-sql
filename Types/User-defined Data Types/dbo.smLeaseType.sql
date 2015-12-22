CREATE TYPE [dbo].[smLeaseType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLeaseType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smLeaseType_rl]', N'[dbo].[smLeaseType]'
GO
EXEC sp_bindefault N'[dbo].[smLeaseType_df]', N'[dbo].[smLeaseType]'
GO
