CREATE TYPE [dbo].[smPONumber] FROM varchar (16) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPONumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smPONumber]'
GO
