CREATE TYPE [dbo].[mbbmudtMemberNameType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtMemberNameType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulMemberNameType]', N'[dbo].[mbbmudtMemberNameType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtMemberNameType]'
GO
