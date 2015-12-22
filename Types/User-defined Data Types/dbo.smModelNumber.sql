CREATE TYPE [dbo].[smModelNumber] FROM varchar (32) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smModelNumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smModelNumber]'
GO
