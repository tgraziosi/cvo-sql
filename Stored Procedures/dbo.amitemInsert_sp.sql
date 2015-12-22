SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amitemInsert_sp] 
( 
	@co_asset_id 	smSurrogateKey, 
	@sequence_id 	smSurrogateKey, 
	@posting_flag 	smPostingState, 
	@co_trx_id 	smSurrogateKey, 
	@manufacturer 	smStdDescription, 
	@model_num 	smModelNumber, 
	@serial_num 	smSerialNumber, 
	@item_code 	smItemCode, 
	@item_description 	smStdDescription, 
	@po_ctrl_num 	smPONumber, 
	@contract_number 	smContractNumber, 
	@vendor_code 	smVendorCode, 
	@vendor_description 	smStdDescription, 
	@invoice_num 	smInvoiceNumber, 
	@invoice_date 	varchar(30), 
	@original_cost 	smMoneyZero, 
	@manufacturer_warranty 	smLogicalTrue, 
	@vendor_warranty 	smLogicalTrue,
	@item_tag						smTag,
	@item_quantity					smQuantity,
	@item_disposition_date			varchar(30),
	@last_modified_date				varchar(30),
	@modified_by					smUserID 
) 
AS 

DECLARE 
	@rowcount 	smCounter,
	@error 		smErrorCode, 
	@ts			timestamp, 
	@message 	smErrorLongDesc

INSERT INTO amitem 
( 
	co_asset_id,
	sequence_id,
	posting_flag,
	co_trx_id,
	manufacturer,
	model_num,
	serial_num,
	item_code,
	item_description,
	po_ctrl_num,
	contract_number,
	vendor_code,
	vendor_description,
	invoice_num,
	invoice_date, 
	original_cost,
	manufacturer_warranty,
	vendor_warranty,
	item_tag,
	item_quantity,
	item_disposition_date,
	last_modified_date,
	modified_by 
)
VALUES
(
	@co_asset_id,
	@sequence_id,
 	@posting_flag,
	@co_trx_id,
	@manufacturer,
	@model_num,
	@serial_num,
	@item_code,
	@item_description,
	@po_ctrl_num,
	@contract_number,
	@vendor_code,
	@vendor_description,
 	@invoice_num,
	@invoice_date,
	@original_cost,
	@manufacturer_warranty,
	@vendor_warranty,
	@item_tag,
	@item_quantity,
	@item_disposition_date,
	@last_modified_date,
	@modified_by
)

RETURN @@error 
GO
GRANT EXECUTE ON  [dbo].[amitemInsert_sp] TO [public]
GO
