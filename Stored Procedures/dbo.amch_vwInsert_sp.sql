SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amch_vwInsert_sp]
(
	@company_id				smallint,
	@trx_ctrl_num           varchar(16),
	@sequence_id            int,		   
	@line_id                smCounter,
	@line_desc              varchar(60), 	
	@gl_exp_acct            varchar(32),  
	@reference_code         varchar(32), 	
	@amt_charged            float,		  	
	@qty_received           float,		  	
	@co_asset_id            smSurrogateKey,
	@asset_ctrl_num         smControlNumber,
	@line_description       smStdDescription,
	@quantity               smQuantity,
	@update_asset_quantity	smLogical,
	@asset_amount			smMoneyZero,
	@imm_exp_amount			smMoneyZero,
	@imm_exp_acct			smAccountCode,
	@imm_exp_ref_code		smAccountReferenceCode,
	@create_item            smLogicalTrue,
	@activity_type          smTrxType,
	@apply_date             smISODate,
	@asset_tag				smTag,
	@item_tag				smTag,
	@last_modified_date     smISODate,
	@modified_by            smUserID,
	@org_id			varchar(30) = NULL
) 
AS

DECLARE 
	@result 		smErrorCode







IF @line_id = 0
BEGIN
	SELECT 	@line_id 		= ISNULL(MAX(line_id), 0) + 1
	FROM	amapdet
	WHERE	company_id		= @company_id
	AND		trx_ctrl_num	= @trx_ctrl_num
	AND		sequence_id		= @sequence_id

	IF @line_id = 1
		SELECT @line_id = 2

END




IF (DATALENGTH(ISNULL(RTRIM(LTRIM(@org_id)),''))=0) 
BEGIN
	SELECT @org_id = organization_id
	FROM Organization
	WHERE outline_num = '1'	
END


INSERT INTO amapdet
(
	company_id,
	trx_ctrl_num,
	sequence_id,
	line_id,
	co_asset_id,
	asset_ctrl_num,
	line_description,
	fixed_asset_acct,
	fixed_asset_ref_code,
	quantity,
	update_asset_quantity,
	asset_amount,
	imm_exp_amount,
	imm_exp_acct,
	imm_exp_ref_code,
	create_item,
	asset_tag,
	item_tag,
	activity_type,
	apply_date,
	completed_date,
	completed_by,
	co_trx_id,
	item_id,
	last_modified_date,
	modified_by,
	org_id
)
VALUES
(
	@company_id,
	@trx_ctrl_num,
	@sequence_id,
	@line_id,
	@co_asset_id,
	@asset_ctrl_num,
	@line_description,
	@gl_exp_acct,
	@reference_code,
	@quantity,
	@update_asset_quantity,
	@asset_amount,
	@imm_exp_amount,
	@imm_exp_acct,
	@imm_exp_ref_code,
	@create_item,
	@asset_tag,
	@item_tag,
	@activity_type,
	@apply_date,
	null,
	0,
	0,
	-1,
	@last_modified_date,
	@modified_by,
	@org_id
	
)

SELECT @result = @@error
IF @result <> 0
	RETURN @result

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amch_vwInsert_sp] TO [public]
GO
