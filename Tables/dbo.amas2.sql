CREATE TABLE [dbo].[amas2]
(
[company_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[sequence_id] [dbo].[smSurrogateKey] NOT NULL,
[item_description] [dbo].[smStdDescription] NOT NULL,
[item_code] [dbo].[smItemCode] NOT NULL,
[item_quantity] [dbo].[smQuantity] NOT NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[date_item_disposition] [dbo].[smApplyDate] NULL,
[date_last_modified] [dbo].[smApplyDate] NOT NULL,
[user_name] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[manufacturer] [dbo].[smStdDescription] NOT NULL,
[model_num] [dbo].[smModelNumber] NOT NULL,
[serial_num] [dbo].[smSerialNumber] NOT NULL,
[item_tag] [dbo].[smTag] NOT NULL,
[vendor_code] [dbo].[smVendorCode] NOT NULL,
[vendor_description] [dbo].[smStdDescription] NOT NULL,
[invoice_num] [dbo].[smInvoiceNumber] NOT NULL,
[po_ctrl_num] [dbo].[smPONumber] NOT NULL,
[x_item_quantity] [dbo].[smQuantity] NOT NULL,
[x_original_cost] [dbo].[smMoneyZero] NOT NULL,
[x_date_item_disposition] [dbo].[smApplyDate] NULL,
[x_date_last_modified] [dbo].[smApplyDate] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amas2_ind_0] ON [dbo].[amas2] ([co_asset_id]) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas2].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas2].[sequence_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[item_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[item_code]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amas2].[item_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas2].[original_cost]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[manufacturer]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[model_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[serial_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[item_tag]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[vendor_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[vendor_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[invoice_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amas2].[po_ctrl_num]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amas2].[x_item_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amas2].[x_original_cost]'
GO
GRANT REFERENCES ON  [dbo].[amas2] TO [public]
GO
GRANT SELECT ON  [dbo].[amas2] TO [public]
GO
GRANT INSERT ON  [dbo].[amas2] TO [public]
GO
GRANT DELETE ON  [dbo].[amas2] TO [public]
GO
GRANT UPDATE ON  [dbo].[amas2] TO [public]
GO
