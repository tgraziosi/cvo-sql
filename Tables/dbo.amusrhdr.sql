CREATE TABLE [dbo].[amusrhdr]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[user_field_id] [dbo].[smUserFieldID] NOT NULL,
[user_field_subid] [tinyint] NOT NULL,
[user_field_type] [dbo].[smUserFieldType] NOT NULL,
[user_field_title] [dbo].[smUserFieldTitle] NULL,
[user_field_length] [dbo].[smCounter] NULL,
[validation_proc] [dbo].[smLongDesc] NULL,
[zoom_id] [dbo].[smCounter] NULL,
[min_value] [dbo].[smMoneyZero] NULL,
[max_value] [dbo].[smMoneyZero] NULL,
[selection] [dbo].[smLongDesc] NULL,
[allow_null] [dbo].[smLogicalTrue] NULL,
[default_value] [dbo].[smStdDescription] NULL,
[last_updated] [dbo].[smApplyDate] NOT NULL,
[updated_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amusrhdr_ind_0] ON [dbo].[amusrhdr] ([company_id], [user_field_id], [user_field_subid]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrhdr].[user_field_length]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrhdr].[zoom_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrhdr].[min_value]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrhdr].[max_value]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amusrhdr].[allow_null]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amusrhdr].[allow_null]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amusrhdr].[default_value]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amusrhdr].[updated_by]'
GO
GRANT REFERENCES ON  [dbo].[amusrhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amusrhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amusrhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amusrhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amusrhdr] TO [public]
GO
