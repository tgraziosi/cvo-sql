CREATE TYPE [dbo].[smDeprMethodID] FROM smallint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smDeprMethodID] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smDeprMethodID_rl]', N'[dbo].[smDeprMethodID]'
GO
EXEC sp_bindefault N'[dbo].[smDeprMethodID_df]', N'[dbo].[smDeprMethodID]'
GO
