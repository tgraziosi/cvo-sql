CREATE TYPE [dbo].[mbbmudtOLAPDimType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPDimType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPDimType]', N'[dbo].[mbbmudtOLAPDimType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPDimType]'
GO
