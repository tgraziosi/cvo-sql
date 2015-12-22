CREATE TYPE [dbo].[mbbmudtOLAPObjectType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPObjectType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPObjectType]', N'[dbo].[mbbmudtOLAPObjectType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPObjectType]'
GO
