CREATE TABLE [dbo].[amtblhdr]
(
[timestamp] [timestamp] NOT NULL,
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[tbl_name] [dbo].[smName] NOT NULL,
[tbl_id] [dbo].[smCounter] NOT NULL,
[tbl_is_child] [dbo].[smLogicalFalse] NOT NULL,
[tbl_explain] [dbo].[smStdDescription] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [amtblhdr_ind_1] ON [dbo].[amtblhdr] ([tbl_id]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtblhdr_ind_0] ON [dbo].[amtblhdr] ([tbl_name]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblhdr].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtblhdr].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblhdr].[tbl_id]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblhdr].[tbl_is_child]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtblhdr].[tbl_is_child]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amtblhdr].[tbl_explain]'
GO
GRANT REFERENCES ON  [dbo].[amtblhdr] TO [public]
GO
GRANT SELECT ON  [dbo].[amtblhdr] TO [public]
GO
GRANT INSERT ON  [dbo].[amtblhdr] TO [public]
GO
GRANT DELETE ON  [dbo].[amtblhdr] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtblhdr] TO [public]
GO
