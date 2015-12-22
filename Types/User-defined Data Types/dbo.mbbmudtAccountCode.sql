CREATE TYPE [dbo].[mbbmudtAccountCode] FROM varchar (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtAccountCode] TO [public]
GO
