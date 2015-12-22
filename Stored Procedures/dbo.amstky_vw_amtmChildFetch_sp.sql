SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amstky_vw_amtmChildFetch_sp]
(
	@rowsrequested		smallint = 1,	 	
	@co_asset_id		smSurrogateKey,		
	@sequence_id		smSurrogateKey		
)
AS

CREATE TABLE #temp 
( 
	timestamp 				varbinary(8) 	null,
	co_asset_id 			int 			null,
	sequence_id 			int 			null,
	posting_flag 			tinyint 		null,
	co_trx_id 				int 			null,
	manufacturer 			varchar(40) 	null,
	model_num 				varchar(32) 	null,
	serial_num 				varchar(32) 	null,
	item_code 				varchar(18) 	null,
	item_description 		varchar(40) 	null,
	po_ctrl_num 			varchar(16) 	null,
	contract_number 		char(16) 		null,
	vendor_code 			varchar(12) 	null,
	vendor_description 		varchar(40) 	null,
	invoice_num 			char(32) 		null,
	invoice_date 			datetime 		null,
	original_cost 			float 			null,
	manufacturer_warranty 	tinyint 		null,
	vendor_warranty 		tinyint 		null,
	item_tag				char(32) 		null,
	item_quantity			int				null,
	item_disposition_date	datetime		null,
	last_modified_date		datetime 		null,
	modified_by				int				null 
)

DECLARE 
	@rowsfound 		smallint, 
	@MSKsequence_id smSurrogateKey 

SELECT @rowsfound = 0 
SELECT @MSKsequence_id = @sequence_id 

IF EXISTS (SELECT 	co_asset_id 
			FROM 	amitem 
			WHERE 	co_asset_id = @co_asset_id 
			AND 	sequence_id = @MSKsequence_id)

BEGIN 
	WHILE @MSKsequence_id IS NOT NULL AND @rowsfound < @rowsrequested 
	BEGIN 

	 	INSERT INTO #temp 
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
				invoice_date, 
				original_cost,
				manufacturer_warranty,
				vendor_warranty,
				item_tag,
				item_quantity,
				item_disposition_date,
				last_modified_date,
				modified_by 
		FROM 	amitem 
		WHERE 	co_asset_id = @co_asset_id 
		AND 	sequence_id = @MSKsequence_id 

		SELECT @rowsfound = @rowsfound + @@rowcount 
	 
	 	 
		SELECT 	@MSKsequence_id = MIN(sequence_id) 
		FROM 	amitem 
		WHERE 	co_asset_id 	= @co_asset_id 
		AND 	sequence_id 	> @MSKsequence_id 
	END 

END 

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
	item_disposition_date 	= CONVERT(char(8), item_disposition_date, 112),
	last_modified_date 		= CONVERT(char(8), last_modified_date, 112),
	modified_by 
FROM #temp 
ORDER BY co_asset_id, sequence_id
 
DROP TABLE #temp 

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amstky_vw_amtmChildFetch_sp] TO [public]
GO
