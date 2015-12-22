CREATE TYPE [dbo].[smPolicyNumber] FROM varchar (40) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPolicyNumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smPolicyNumber]'
GO
