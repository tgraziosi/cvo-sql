CREATE TYPE [dbo].[mbbmudtUser] FROM varchar (30) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtUser] TO [public]
GO
EXEC sp_bindefault N'[dbo].[mbbmdefEmpty]', N'[dbo].[mbbmudtUser]'
GO
