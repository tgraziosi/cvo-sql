CREATE TYPE [dbo].[mbbmudtBaseDateType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtBaseDateType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulBaseDateType]', N'[dbo].[mbbmudtBaseDateType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtBaseDateType]'
GO
