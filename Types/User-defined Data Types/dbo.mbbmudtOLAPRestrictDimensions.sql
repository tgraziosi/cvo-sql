CREATE TYPE [dbo].[mbbmudtOLAPRestrictDimensions] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPRestrictDimensions] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmudtOLAPRestrictDimensions]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPRestrictDimensions]'
GO
