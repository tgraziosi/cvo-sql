CREATE TYPE [dbo].[smContractNumber] FROM char (16) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smContractNumber] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smContractNumber]'
GO
