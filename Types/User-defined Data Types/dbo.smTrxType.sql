CREATE TYPE [dbo].[smTrxType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smTrxType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[smTrxType]'
GO
