CREATE TYPE [dbo].[mbbmudtPublishMethod] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtPublishMethod] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPublishMethod]', N'[dbo].[mbbmudtPublishMethod]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtPublishMethod]'
GO
