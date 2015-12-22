CREATE TYPE [dbo].[smKeyType] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smKeyType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smKeyType_rl]', N'[dbo].[smKeyType]'
GO
