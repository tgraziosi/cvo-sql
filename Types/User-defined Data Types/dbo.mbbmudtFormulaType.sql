CREATE TYPE [dbo].[mbbmudtFormulaType] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtFormulaType] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulFormulaType]', N'[dbo].[mbbmudtFormulaType]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtFormulaType]'
GO
