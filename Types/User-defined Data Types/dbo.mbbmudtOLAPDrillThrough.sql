CREATE TYPE [dbo].[mbbmudtOLAPDrillThrough] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPDrillThrough] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYesNo]', N'[dbo].[mbbmudtOLAPDrillThrough]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPDrillThrough]'
GO
