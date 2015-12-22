CREATE TABLE [dbo].[ampurge]
(
[timestamp] [timestamp] NOT NULL,
[company_id] [dbo].[smCompanyID] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[asset_description] [dbo].[smStdDescription] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[mass_maintenance_id] [dbo].[smSurrogateKey] NOT NULL,
[activity_state] [dbo].[smSystemState] NOT NULL,
[comment] [dbo].[smLongDesc] NULL,
[last_updated] [dbo].[smApplyDate] NOT NULL,
[updated_by] [dbo].[smUserID] NOT NULL,
[date_created] [dbo].[smApplyDate] NOT NULL,
[created_by] [dbo].[smUserID] NOT NULL,
[acquisition_date] [dbo].[smApplyDate] NOT NULL,
[disposition_date] [dbo].[smApplyDate] NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[lp_fiscal_period_end] [dbo].[smApplyDate] NULL,
[lp_accum_depr] [dbo].[smMoneyZero] NULL,
[lp_current_cost] [dbo].[smMoneyZero] NULL
) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[ampurge].[asset_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[mass_maintenance_id]'
GO
EXEC sp_bindrule N'[dbo].[smSystemState_rl]', N'[dbo].[ampurge].[activity_state]'
GO
EXEC sp_bindefault N'[dbo].[smSystemState_df]', N'[dbo].[ampurge].[activity_state]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[updated_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[created_by]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[lp_accum_depr]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[ampurge].[lp_current_cost]'
GO
GRANT REFERENCES ON  [dbo].[ampurge] TO [public]
GO
GRANT SELECT ON  [dbo].[ampurge] TO [public]
GO
GRANT INSERT ON  [dbo].[ampurge] TO [public]
GO
GRANT DELETE ON  [dbo].[ampurge] TO [public]
GO
GRANT UPDATE ON  [dbo].[ampurge] TO [public]
GO
