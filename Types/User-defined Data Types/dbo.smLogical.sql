CREATE TYPE [dbo].[smLogical] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLogical] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[smLogical]'
GO
