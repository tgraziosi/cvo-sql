CREATE TYPE [dbo].[smLogicalFalse] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLogicalFalse] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[smLogicalFalse]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[smLogicalFalse]'
GO
