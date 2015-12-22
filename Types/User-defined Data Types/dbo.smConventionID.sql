CREATE TYPE [dbo].[smConventionID] FROM tinyint NOT NULL
GO
GRANT REFERENCES ON TYPE:: [dbo].[smConventionID] TO [public]
GO
EXEC sp_bindrule N'[dbo].[smConventionID_rl]', N'[dbo].[smConventionID]'
GO
EXEC sp_bindefault N'[dbo].[smConventionID_df]', N'[dbo].[smConventionID]'
GO
