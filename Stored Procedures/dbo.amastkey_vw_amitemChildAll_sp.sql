SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amastkey_vw_amitemChildAll_sp] 
( 
	@co_asset_id	smSurrogateKey 
) 
AS 

SELECT 
	timestamp,
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
	invoice_date 			= CONVERT(char(8), invoice_date, 112), 
	original_cost,
	manufacturer_warranty,
	vendor_warranty,
	item_tag,
	item_quantity,
	item_disposition_date	= CONVERT(char(8), item_disposition_date, 112),
	last_modified_date 		= CONVERT(char(8), last_modified_date, 112),
	modified_by 
FROM 
	amitem 
WHERE 
	co_asset_id = @co_asset_id 
ORDER BY 
	co_asset_id, 
	sequence_id 

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amastkey_vw_amitemChildAll_sp] TO [public]
GO
