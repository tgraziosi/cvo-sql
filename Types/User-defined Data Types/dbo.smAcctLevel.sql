CREATE TYPE [dbo].[smAcctLevel] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smAcctLevel] TO [public]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[smAcctLevel]'
GO
