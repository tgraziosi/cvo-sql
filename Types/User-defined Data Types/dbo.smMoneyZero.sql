CREATE TYPE [dbo].[smMoneyZero] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smMoneyZero] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smMoneyZero]'
GO
