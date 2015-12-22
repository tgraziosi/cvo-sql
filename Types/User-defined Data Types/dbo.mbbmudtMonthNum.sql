CREATE TYPE [dbo].[mbbmudtMonthNum] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtMonthNum] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulMonthNum]', N'[dbo].[mbbmudtMonthNum]'
GO
