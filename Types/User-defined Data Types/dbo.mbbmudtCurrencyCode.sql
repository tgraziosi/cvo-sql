CREATE TYPE [dbo].[mbbmudtCurrencyCode] FROM varchar (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[mbbmudtCurrencyCode] TO [public]
GO
