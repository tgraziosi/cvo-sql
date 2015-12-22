CREATE TYPE [dbo].[mbbmudtOLAPCubeAccess] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPCubeAccess] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPCubeAccess]', N'[dbo].[mbbmudtOLAPCubeAccess]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPCubeAccess]'
GO
