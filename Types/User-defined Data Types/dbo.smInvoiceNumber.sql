CREATE TYPE [dbo].[smInvoiceNumber] FROM char (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smInvoiceNumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smInvoiceNumber]'
GO
