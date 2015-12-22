CREATE TYPE [dbo].[smLife] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLife] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smLife]'
GO
