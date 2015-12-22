CREATE TYPE [dbo].[mbbmudtOLAPPeriodType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPPeriodType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPPeriodType]', N'[dbo].[mbbmudtOLAPPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPPeriodType]'
GO
