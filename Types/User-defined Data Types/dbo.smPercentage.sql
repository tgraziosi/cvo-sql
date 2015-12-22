CREATE TYPE [dbo].[smPercentage] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smPercentage] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smPercentage_df]', N'[dbo].[smPercentage]'
GO
