CREATE TYPE [dbo].[smSerialNumber] FROM varchar (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smSerialNumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smSerialNumber]'
GO
