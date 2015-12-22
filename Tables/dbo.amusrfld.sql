CREATE TABLE [dbo].[amusrfld]
(
[timestamp] [timestamp] NOT NULL,
[user_field_id] [dbo].[smSurrogateKey] NOT NULL,
[user_code_1] [dbo].[smStdDescription] NOT NULL,
[user_code_2] [dbo].[smStdDescription] NOT NULL,
[user_code_3] [dbo].[smStdDescription] NOT NULL,
[user_code_4] [dbo].[smStdDescription] NOT NULL,
[user_code_5] [dbo].[smStdDescription] NOT NULL,
[user_date_1] [dbo].[smApplyDate] NULL,
[user_date_2] [dbo].[smApplyDate] NULL,
[user_date_3] [dbo].[smApplyDate] NULL,
[user_date_4] [dbo].[smApplyDate] NULL,
[user_date_5] [dbo].[smApplyDate] NULL,
[user_amount_1] [dbo].[smMoneyZero] NOT NULL,
[user_amount_2] [dbo].[smMoneyZero] NOT NULL,
[user_amount_3] [dbo].[smMoneyZero] NOT NULL,
[user_amount_4] [dbo].[smMoneyZero] NOT NULL,
[user_amount_5] [dbo].[smMoneyZero] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amusrfld_ind_0] ON [dbo].[amusrfld] ([user_field_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_field_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrfld].[user_code_1]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrfld].[user_code_2]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrfld].[user_code_3]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrfld].[user_code_4]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrfld].[user_code_5]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_amount_1]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_amount_2]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_amount_3]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_amount_4]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrfld].[user_amount_5]'
GO
GRANT REFERENCES ON  [dbo].[amusrfld] TO [public]
GO
GRANT SELECT ON  [dbo].[amusrfld] TO [public]
GO
GRANT INSERT ON  [dbo].[amusrfld] TO [public]
GO
GRANT DELETE ON  [dbo].[amusrfld] TO [public]
GO
GRANT UPDATE ON  [dbo].[amusrfld] TO [public]
GO
