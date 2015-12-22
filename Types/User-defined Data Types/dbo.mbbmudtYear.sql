CREATE TYPE [dbo].[mbbmudtYear] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtYear] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulYear]', N'[dbo].[mbbmudtYear]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtYear]'
GO
