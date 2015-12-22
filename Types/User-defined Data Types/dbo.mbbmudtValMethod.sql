CREATE TYPE [dbo].[mbbmudtValMethod] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtValMethod] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulValMethod]', N'[dbo].[mbbmudtValMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef3]', N'[dbo].[mbbmudtValMethod]'
GO
