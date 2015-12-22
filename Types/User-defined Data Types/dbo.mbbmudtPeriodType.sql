CREATE TYPE [dbo].[mbbmudtPeriodType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtPeriodType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulPeriodType]', N'[dbo].[mbbmudtPeriodType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtPeriodType]'
GO
