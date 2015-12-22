CREATE TYPE [dbo].[mbbmudtOLAPLevelType] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPLevelType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPLevelType]', N'[dbo].[mbbmudtOLAPLevelType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPLevelType]'
GO
