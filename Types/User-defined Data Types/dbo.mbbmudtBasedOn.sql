CREATE TYPE [dbo].[mbbmudtBasedOn] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtBasedOn] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulBasedOn]', N'[dbo].[mbbmudtBasedOn]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtBasedOn]'
GO
