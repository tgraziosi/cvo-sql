SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amstky_vw_amct_vwChildFetch_sp] 
( 
	@rowsrequested		smallint = 1,		
	@co_asset_id		smSurrogateKey,		
	@co_trx_id			smSurrogateKey 		
) 
AS 

SELECT 
	timestamp,
	company_id,
	journal_ctrl_num,
	co_trx_id,
	trx_type,
	last_modified_date 	= CONVERT(char(8), last_modified_date, 112),
	modified_by,
	apply_date 			= CONVERT(char(8), apply_date, 112),
	posting_flag,
	date_posted 		= CONVERT(char(8), date_posted, 112),
	hold_flag,
	trx_description,
	doc_reference,
	note_id,
	user_field_id,
	total_received,
	linked_trx,
	revaluation_rate,
	trx_source,
	co_asset_id,
	change_in_quantity,
	fixed_asset_account_id,
	fixed_asset_account_code,
	fixed_asset_ref_code,
	imm_exp_account_id,
	imm_exp_account_code,
	imm_exp_ref_code

FROM 	amact_vw 
WHERE	co_trx_id	= @co_trx_id
AND		co_asset_id	= @co_asset_id

RETURN 0 
GO
GRANT EXECUTE ON  [dbo].[amstky_vw_amct_vwChildFetch_sp] TO [public]
GO
