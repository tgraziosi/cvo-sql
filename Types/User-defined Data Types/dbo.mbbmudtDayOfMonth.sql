CREATE TYPE [dbo].[mbbmudtDayOfMonth] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtDayOfMonth] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulDayOfMonth]', N'[dbo].[mbbmudtDayOfMonth]'
GO
