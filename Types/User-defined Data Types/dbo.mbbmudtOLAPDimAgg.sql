CREATE TYPE [dbo].[mbbmudtOLAPDimAgg] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtOLAPDimAgg] TO [public]
GO
EXEC sp_bindrule N'[dbo].[mbbmrulOLAPDimAgg]', N'[dbo].[mbbmudtOLAPDimAgg]'
GO
EXEC sp_bindefault N'[dbo].[mbbmdef0]', N'[dbo].[mbbmudtOLAPDimAgg]'
GO
