CREATE TABLE [dbo].[amtrxact]
(
[timestamp] [timestamp] NOT NULL,
[system_defined] [dbo].[smLogicalFalse] NOT NULL,
[display_order] [dbo].[smCounter] NOT NULL,
[import_order] [dbo].[smCounter] NOT NULL,
[trx_type] [dbo].[smTrxType] NOT NULL,
[account_type] [dbo].[smAccountTypeID] NOT NULL,
[debit_positive] [dbo].[smLogicalFalse] NOT NULL,
[credit_positive] [dbo].[smLogicalFalse] NOT NULL,
[debit_negative] [dbo].[smLogicalFalse] NOT NULL,
[credit_negative] [dbo].[smLogicalFalse] NOT NULL,
[auto_balancing] [dbo].[smLogicalFalse] NOT NULL,
[last_updated] [dbo].[smApplyDate] NOT NULL,
[updated_by] [dbo].[smUserID] NOT NULL,
[date_created] [dbo].[smApplyDate] NOT NULL,
[created_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amtrxact_ind_0] ON [dbo].[amtrxact] ([trx_type], [account_type]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[system_defined]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxact].[display_order]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxact].[import_order]'
GO
EXEC sp_bindrule N'[dbo].[smTrxType_rl]', N'[dbo].[amtrxact].[trx_type]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[debit_positive]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[debit_positive]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[credit_positive]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[credit_positive]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[debit_negative]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[debit_negative]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[credit_negative]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[credit_negative]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amtrxact].[auto_balancing]'
GO
EXEC sp_bindefault N'[dbo].[smFalse_df]', N'[dbo].[amtrxact].[auto_balancing]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxact].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amtrxact].[created_by]'
GO
GRANT REFERENCES ON  [dbo].[amtrxact] TO [public]
GO
GRANT SELECT ON  [dbo].[amtrxact] TO [public]
GO
GRANT INSERT ON  [dbo].[amtrxact] TO [public]
GO
GRANT DELETE ON  [dbo].[amtrxact] TO [public]
GO
GRANT UPDATE ON  [dbo].[amtrxact] TO [public]
GO
