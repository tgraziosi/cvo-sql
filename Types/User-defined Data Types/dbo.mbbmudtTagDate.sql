CREATE TYPE [dbo].[mbbmudtTagDate] FROM smalldatetime NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtTagDate] TO [public]
GO
EXEC sp_bindefault N'[dbo].[mbbmdefDate]', N'[dbo].[mbbmudtTagDate]'
GO
