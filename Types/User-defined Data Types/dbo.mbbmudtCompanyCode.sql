CREATE TYPE [dbo].[mbbmudtCompanyCode] FROM varchar (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtCompanyCode] TO [public]
GO
