CREATE TYPE [dbo].[smPercentZero] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPercentZero] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smPercentZero]'
GO
