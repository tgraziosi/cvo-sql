CREATE TYPE [dbo].[mbbmudtHomeNatural] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtHomeNatural] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulHomeNatural]', N'[dbo].[mbbmudtHomeNatural]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtHomeNatural]'
GO
