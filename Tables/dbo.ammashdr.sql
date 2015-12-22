CREATE TABLE [dbo].[ammashdr]
(
[timestamp] [timestamp] NOT NULL,
[mass_maintenance_id] [dbo].[smSurrogateKey] NOT NULL,
[mass_description] [dbo].[smStdDescription] NOT NULL,
[one_at_a_time] [dbo].[smLogical] NOT NULL,
[user_id] [dbo].[smUserID] NOT NULL,
[group_id] [dbo].[smSurrogateKey] NOT NULL,
[assets_purged] [dbo].[smLogical] NOT NULL,
[process_start_date] [dbo].[smApplyDate] NULL,
[process_end_date] [dbo].[smApplyDate] NULL,
[error_code] [dbo].[smErrorCode] NOT NULL,
[error_message] [dbo].[smErrorLongDesc] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [ammashdr_ind_0] ON [dbo].[ammashdr] ([mass_maintenance_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammashdr].[mass_maintenance_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[ammashdr].[mass_description]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ammashdr].[one_at_a_time]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammashdr].[user_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ammashdr].[group_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[ammashdr].[assets_purged]'
GO
GRANT REFERENCES ON  [dbo].[ammashdr] TO [public]
GO
GRANT SELECT ON  [dbo].[ammashdr] TO [public]
GO
GRANT INSERT ON  [dbo].[ammashdr] TO [public]
GO
GRANT DELETE ON  [dbo].[ammashdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[ammashdr] TO [public]
GO
