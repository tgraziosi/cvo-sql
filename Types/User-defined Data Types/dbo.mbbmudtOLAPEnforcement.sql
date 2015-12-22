CREATE TYPE [dbo].[mbbmudtOLAPEnforcement] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPEnforcement] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPEnforcement]', N'[dbo].[mbbmudtOLAPEnforcement]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPEnforcement]'
GO
