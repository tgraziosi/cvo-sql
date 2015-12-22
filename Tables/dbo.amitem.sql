CREATE TABLE [dbo].[amitem]
(
[timestamp] [timestamp] NOT NULL,
[co_asset_id] [dbo].[smSurrogateKey] NOT NULL,
[sequence_id] [dbo].[smSurrogateKey] NOT NULL,
[posting_flag] [dbo].[smPostingState] NOT NULL,
[co_trx_id] [dbo].[smSurrogateKey] NOT NULL,
[manufacturer] [dbo].[smStdDescription] NOT NULL,
[model_num] [dbo].[smModelNumber] NOT NULL,
[serial_num] [dbo].[smSerialNumber] NOT NULL,
[item_code] [dbo].[smItemCode] NOT NULL,
[item_description] [dbo].[smStdDescription] NOT NULL,
[po_ctrl_num] [dbo].[smPONumber] NOT NULL,
[contract_number] [dbo].[smContractNumber] NOT NULL,
[vendor_code] [dbo].[smVendorCode] NOT NULL,
[vendor_description] [dbo].[smStdDescription] NOT NULL,
[invoice_num] [dbo].[smInvoiceNumber] NOT NULL,
[invoice_date] [dbo].[smApplyDate] NULL,
[original_cost] [dbo].[smMoneyZero] NOT NULL,
[manufacturer_warranty] [dbo].[smLogicalTrue] NOT NULL,
[vendor_warranty] [dbo].[smLogicalTrue] NOT NULL,
[item_tag] [dbo].[smTag] NOT NULL,
[item_quantity] [dbo].[smQuantity] NOT NULL,
[item_disposition_date] [dbo].[smApplyDate] NULL,
[last_modified_date] [dbo].[smApplyDate] NOT NULL,
[modified_by] [dbo].[smUserID] NOT NULL
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [amitem_ind_0] ON [dbo].[amitem] ([co_asset_id], [sequence_id]) WITH (FILLFACTOR=70) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amitem].[co_asset_id]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amitem].[sequence_id]'
GO
EXEC sp_bindefault N'[dbo].[smPostingState_df]', N'[dbo].[amitem].[posting_flag]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amitem].[co_trx_id]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[manufacturer]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[model_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[serial_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[item_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[item_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[po_ctrl_num]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[contract_number]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[vendor_code]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[vendor_description]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[invoice_num]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amitem].[original_cost]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amitem].[manufacturer_warranty]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amitem].[manufacturer_warranty]'
GO
EXEC sp_bindrule N'[dbo].[smLogical_rl]', N'[dbo].[amitem].[vendor_warranty]'
GO
EXEC sp_bindefault N'[dbo].[smTrue_df]', N'[dbo].[amitem].[vendor_warranty]'
GO
EXEC sp_bindefault N'[dbo].[smEmptyString_df]', N'[dbo].[amitem].[item_tag]'
GO
EXEC sp_bindefault N'[dbo].[smQuantity_df]', N'[dbo].[amitem].[item_quantity]'
GO
EXEC sp_bindefault N'[dbo].[smZero_df]', N'[dbo].[amitem].[modified_by]'
GO
GRANT REFERENCES ON  [dbo].[amitem] TO [public]
GO
GRANT SELECT ON  [dbo].[amitem] TO [public]
GO
GRANT INSERT ON  [dbo].[amitem] TO [public]
GO
GRANT DELETE ON  [dbo].[amitem] TO [public]
GO
GRANT UPDATE ON  [dbo].[amitem] TO [public]
GO
