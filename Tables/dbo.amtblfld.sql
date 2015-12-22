CREATE TABLE [dbo].[amtblfld]
(
[timestamp] [timestamp] NOT NULL,
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[tbl_id] [dbo].[smCounter] NOT NULL,
[fld_id] [dbo].[smCounter] NOT NULL,
[length] [dbo].[smCounter] NOT NULL,
[s_type] [dbo].[smCounter] NOT NULL,
[key_nr] [dbo].[smCounter] NOT NULL,
[key_fixed] [dbo].[smLogicalFalse] NOT NULL,
[null_allow] [dbo].[smLogicalTrue] NOT NULL,
[popup_mnu] [dbo].[smCounter] NOT NULL,
[zoom_id] [dbo].[smCounter] NOT NULL,
[name] [dbo].[smName] NOT NULL,
[fld_default] [dbo].[smStdDescription] NULL,
[validation_proc] [dbo].[smStdDescription] NULL,
[foreign_key] [dbo].[smStdDescription] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtblfld_ind_0] ON [dbo].[amtblfld] ([tbl_id], [fld_id]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblfld].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtblfld].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[tbl_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[fld_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[length]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[s_type]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[key_nr]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblfld].[key_fixed]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtblfld].[key_fixed]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblfld].[null_allow]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amtblfld].[null_allow]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[popup_mnu]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblfld].[zoom_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtblfld].[fld_default]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtblfld].[validation_proc]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtblfld].[foreign_key]'
GO
GRANT REFERENCES ON  [dbo].[amtblfld] TO [public]
GO
GRANT SELECT ON  [dbo].[amtblfld] TO [public]
GO
GRANT INSERT ON  [dbo].[amtblfld] TO [public]
GO
GRANT DELETE ON  [dbo].[amtblfld] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtblfld] TO [public]
GO
