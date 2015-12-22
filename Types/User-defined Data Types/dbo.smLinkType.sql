CREATE TYPE [dbo].[smLinkType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLinkType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smLinkType_rl]', N'[dbo].[smLinkType]'
GO
EXEC sp_bindefault N'[dbo].[smLinkType_df]', N'[dbo].[smLinkType]'
GO
