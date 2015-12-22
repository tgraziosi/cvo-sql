CREATE TYPE [dbo].[smUnitsOfMeasure] FROM varchar (16) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smUnitsOfMeasure] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smUnitsOfMeasure]'
GO
