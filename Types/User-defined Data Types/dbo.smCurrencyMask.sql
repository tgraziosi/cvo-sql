CREATE TYPE [dbo].[smCurrencyMask] FROM varchar (100) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCurrencyMask] TO [public]
GO
