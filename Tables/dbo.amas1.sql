CREATE TABLE [dbo].[amas1]
(
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[asset_ctrl_num] [dbo].[smControlNumber] NOT NULL,
[asset_description] [dbo].[smStdDescription] NOT NULL,
[asset_type_code] [dbo].[smAssetTypeCode] NULL,
[activity_state] [varchar] (11) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_new] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_pledged] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_property] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[depreciated] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[is_imported] [varchar] (3) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[lease_type] [varchar] (25) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[orig_quantity] [dbo].[smQuantity] NOT NULL,
[date_acquisition] [dbo].[smApplyDate] NOT NULL,
[date_placed_in_service] [dbo].[smApplyDate] NULL,
[date_disposition] [dbo].[smApplyDate] NULL,
[category_code] [dbo].[smCategoryCode] NOT NULL,
[account_reference_code] [dbo].[smAccountReferenceCode] NOT NULL,
[policy_number] [dbo].[smPolicyNumber] NOT NULL,
[key_1] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[x_original_cost] [dbo].[smMoneyZero] NOT NULL,
[x_orig_quantity] [dbo].[smQuantity] NOT NULL,
[x_date_acquisition] [dbo].[smApplyDate] NOT NULL,
[x_date_placed_in_service] [dbo].[smApplyDate] NULL,
[x_date_disposition] [dbo].[smApplyDate] NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amas1_ind_0] ON [dbo].[amas1] ([co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas1].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas1].[asset_description]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas1].[original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amas1].[orig_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas1].[account_reference_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas1].[policy_number]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas1].[x_original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amas1].[x_orig_quantity]'
GO
GRANT REFERENCES ON  [dbo].[amas1] TO [public]
GO
GRANT SELECT ON  [dbo].[amas1] TO [public]
GO
GRANT INSERT ON  [dbo].[amas1] TO [public]
GO
GRANT DELETE ON  [dbo].[amas1] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas1] TO [public]
GO
