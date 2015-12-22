CREATE TYPE [dbo].[smLastFiller] FROM char (88) NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smLastFiller] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[smLastFiller]'
GO
