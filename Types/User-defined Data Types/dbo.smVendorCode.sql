CREATE TYPE [dbo].[smVendorCode] FROM varchar (12) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smVendorCode] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smVendorCode]'
GO
