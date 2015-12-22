CREATE TYPE [dbo].[smTrxSubtype] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smTrxSubtype] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smTrxSubtype]'
GO
