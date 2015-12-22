CREATE TYPE [dbo].[smCurrencyCode] FROM varchar (8) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smCurrencyCode] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smCurrencyCode]'
GO
