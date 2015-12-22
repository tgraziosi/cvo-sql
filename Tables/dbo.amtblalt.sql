CREATE TABLE [dbo].[amtblalt]
(
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[alt_key] [dbo].[smCounter] NOT NULL,
[tbl_id] [dbo].[smCounter] NOT NULL,
[tbl_alt_id] [dbo].[smCounter] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtblalt_ind_0] ON [dbo].[amtblalt] ([alt_key], [tbl_id]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtblalt].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtblalt].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblalt].[alt_key]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblalt].[tbl_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtblalt].[tbl_alt_id]'
GO
GRANT REFERENCES ON  [dbo].[amtblalt] TO [public]
GO
GRANT SELECT ON  [dbo].[amtblalt] TO [public]
GO
GRANT INSERT ON  [dbo].[amtblalt] TO [public]
GO
GRANT DELETE ON  [dbo].[amtblalt] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtblalt] TO [public]
GO
