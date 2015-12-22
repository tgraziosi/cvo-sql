CREATE TYPE [dbo].[smServiceUnits] FROM int NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smServiceUnits] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smServiceUnits]'
GO
