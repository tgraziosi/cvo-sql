SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amitemUpdate_sp] 
( 
	@timestamp 	timestamp,
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
	@rowcount 	int,
	@error 		int, 
	@ts 		timestamp, 
	@message 	varchar(255)

UPDATE amitem 
SET 
	posting_flag 	= @posting_flag,
	co_trx_id 	= @co_trx_id,
	manufacturer 	= @manufacturer,
	model_num 	= @model_num,
	serial_num 	= @serial_num,
	item_code 	= @item_code,
	item_description 	= @item_description,
	po_ctrl_num 	= @po_ctrl_num,
	contract_number 	= @contract_number,
	vendor_code 	= @vendor_code,
	vendor_description 	= @vendor_description,
	invoice_num 	= @invoice_num,
	invoice_date 	= @invoice_date,
	original_cost 	= @original_cost,
	manufacturer_warranty 	= @manufacturer_warranty,
	vendor_warranty 	= @vendor_warranty,
	item_tag						= @item_tag,
	item_quantity					= @item_quantity,
	item_disposition_date			= @item_disposition_date,
	last_modified_date				= @last_modified_date,
	modified_by						= modified_by 
WHERE 	co_asset_id			 		= @co_asset_id 
AND 	sequence_id					= @sequence_id 
AND 	timestamp					= @timestamp 

SELECT @error = @@error, @rowcount = @@rowcount 
IF @error <> 0  
	RETURN @error 

IF @rowcount = 0  
BEGIN 
	 
	SELECT 	@ts 		= timestamp 
	FROM 	amitem 
	WHERE 	co_asset_id = @co_asset_id 
	AND		sequence_id = @sequence_id 	

	SELECT @error = @@error, @rowcount = @@rowcount 
	IF @error <> 0  
		RETURN @error 

	IF @rowcount = 0  
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20004, "tmp/amitemup.sp", 157, amitem, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20004 @message 
		RETURN 		20004 
	END 

	IF @ts <> @timestamp 
	BEGIN 
		EXEC 		amGetErrorMessage_sp 20003, "tmp/amitemup.sp", 164, amitem, @error_message = @message OUT 
		IF @message IS NOT NULL RAISERROR 	20003 @message 
		RETURN 		20003 
	END 
END 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amitemUpdate_sp] TO [public]
GO
