CREATE TYPE [dbo].[smLogicalTrue] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLogicalTrue] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[smLogicalTrue]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[smLogicalTrue]'
GO
