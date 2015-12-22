SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

 
CREATE PROCEDURE [dbo].[imItmIns_sp] 
( 
	@company_id					smallint,				
	@asset_ctrl_num				char(16),					
	@sequence_id				int,					
	@manufacturer				varchar(40) 	= "",	
	@model_num					varchar(32) 	= "",	
	@serial_num					varchar(32) 	= "",	
	@item_code					varchar(22) 	= "",	
	@item_description			varchar(40) 	= "",	
	@item_tag					varchar(32)		= "",	
	@po_ctrl_num				char(16) 		= "",	
	@contract_number			char(16) 		= "",	
	@vendor_code				char(12)		= "",	
	@vendor_description			varchar(40) 	= "",	
	@invoice_num				varchar(32) 	= "",	
	@invoice_date				char(8) 		= NULL,	
	@item_cost					float 			= 0.00,	
	@item_quantity				int				= 1,	
	@item_disposition_date		char(8)			= NULL,	
	@last_modified_date			char(8) 		= NULL,	
	@modified_by				int 			= 1,	
	@stop_on_error				tinyint			= 0,	
	@debug_level				smallint		= 0		
)
AS 

DECLARE
	@result			int,			
	@message		varchar(255),	
	@co_asset_id	int,			
	@is_valid		tinyint

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmins.sp" + ", line " + STR( 74, 5 ) + " -- ENTRY: "


IF @last_modified_date IS NULL
	SELECT	@last_modified_date = CONVERT(char(8), GETDATE(), 112)

EXEC @result = imItmVal_sp
					@action 					= 0,
					@company_id					= @company_id,
					@asset_ctrl_num				= @asset_ctrl_num,
					@sequence_id				= @sequence_id,
					@manufacturer				= @manufacturer,
					@model_num					= @model_num,
					@serial_num					= @serial_num,
					@item_code					= @item_code,
					@item_description			= @item_description,
					@item_tag					= @item_tag,
					@po_ctrl_num				= @po_ctrl_num,
					@contract_number			= @contract_number,
					@vendor_code				= @vendor_code,
					@vendor_description			= @vendor_description,
					@invoice_num				= @invoice_num,
					@invoice_date				= @invoice_date,
					@item_cost					= @item_cost,
					@item_quantity				= @item_quantity,
					@item_disposition_date		= @item_disposition_date,
					@last_modified_date			= @last_modified_date,
					@modified_by				= @modified_by,
					@stop_on_error				= @stop_on_error,
					@is_valid					= @is_valid			OUTPUT
IF @result <> 0
	RETURN @result

IF @is_valid = 1
BEGIN

	INSERT INTO amitem 
	(
 		co_asset_id,
 		sequence_id,
 		manufacturer,
		model_num,
		serial_num,
		item_code,
		item_description,
		item_tag,
		po_ctrl_num,
		contract_number,
		vendor_code,
		vendor_description,
		invoice_num,
		invoice_date,
		original_cost,
		item_quantity,
		item_disposition_date,
		last_modified_date,
		modified_by		
	)
	SELECT
 		co_asset_id,
 		@sequence_id,
 		@manufacturer,
		@model_num,
		@serial_num,
		@item_code,
		@item_description,
		@item_tag,
		@po_ctrl_num,
		@contract_number,
		@vendor_code,
		@vendor_description,
		@invoice_num,
		@invoice_date,
		@item_cost,
		@item_quantity,
		@item_disposition_date,
		@last_modified_date,
		@modified_by
	FROM	amasset
	WHERE	company_id		= @company_id
	AND		asset_ctrl_num	= @asset_ctrl_num
	
	SELECT 	@result = @@error
	IF @result <> 0
		RETURN 		@result

END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/imitmins.sp" + ", line " + STR( 165, 5 ) + " -- EXIT: "

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[imItmIns_sp] TO [public]
GO
