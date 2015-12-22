CREATE TYPE [dbo].[mbbmudtOLAPCellSecurity] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPCellSecurity] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPCellSecurity]', N'[dbo].[mbbmudtOLAPCellSecurity]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPCellSecurity]'
GO
