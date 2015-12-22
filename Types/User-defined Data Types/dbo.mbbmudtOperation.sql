CREATE TYPE [dbo].[mbbmudtOperation] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOperation] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOperation]', N'[dbo].[mbbmudtOperation]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOperation]'
GO
