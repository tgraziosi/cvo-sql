CREATE TYPE [dbo].[smRevaluationRate] FROM float NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smRevaluationRate] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smRevaluationRate]'
GO
