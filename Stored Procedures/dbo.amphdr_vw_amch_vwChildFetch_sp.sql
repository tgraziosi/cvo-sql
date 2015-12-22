SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[amphdr_vw_amch_vwChildFetch_sp]
(
	@rowsrequested		smallint = 1,
	@company_id			smCompanyID,		 	
	@trx_ctrl_num 		smControlNumber,		
	@sequence_id 		smCounter,				
	@line_id 			smCounter				
) 
AS

CREATE TABLE #temp 
(
	timestamp 				varbinary(8) 	null,
	company_id 				smallint 		null,
	trx_ctrl_num 			varchar(16) 	null,
	sequence_id 			int 			null,
	line_id 				int 			null,
	line_desc 				varchar(60) 	null,
	gl_exp_acct 			varchar(32) 	null,
	reference_code 			varchar(32) 	null,
	amt_extended 			float 			null,
	qty_received 			float 			null,
	co_asset_id 			int 			null,
	asset_ctrl_num 			char(16) 		null,
	line_description 		varchar(40) 	null,
	quantity 				int 			null,
	update_asset_quantity	tinyint			null,
	asset_amount 			float 			null,
	imm_exp_amount 			float 			null,
	imm_exp_acct 			varchar(32) 	null,
	imm_exp_ref_code 		varchar(32) 	null,
	create_item 			tinyint 		null,
	activity_type 			tinyint 		null,
	apply_date 				datetime 		null,
	asset_tag				char(32)		null,
	item_tag				char(32)		null,
	last_modified_date	 	datetime 		null,
	modified_by 			int 			null
)

DECLARE @rowsfound 			smallint
DECLARE @MSKline_id 		smCounter
DECLARE @MSKsequence_id 	int

SELECT @rowsfound = 0
SELECT @MSKline_id = @line_id
SELECT @MSKsequence_id = @sequence_id

IF EXISTS (SELECT * 
			FROM 	amch_vw 
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		= @MSKline_id)
BEGIN
	WHILE @MSKline_id IS NOT NULL AND @rowsfound < @rowsrequested
 	BEGIN

		INSERT INTO #temp 
		SELECT 
				timestamp,
				company_id,
				trx_ctrl_num,
				sequence_id,
				line_id,
				line_desc,
				gl_exp_acct,
				reference_code,
				amt_charged,
				qty_received,
				co_asset_id,
				asset_ctrl_num,
				line_description,
				quantity,
				update_asset_quantity,
				asset_amount,
				imm_exp_amount,
				imm_exp_acct,
				imm_exp_ref_code,
				create_item,
				activity_type,
				apply_date,
				asset_tag,
				item_tag,
				last_modified_date,
				modified_by
		 
		FROM 	amch_vw 
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	= @MSKsequence_id 
		AND		line_id 		= @MSKline_id

		SELECT @rowsfound = @rowsfound + @@rowcount
		
		
		SELECT 	@MSKline_id 	= MIN(line_id) 
		FROM 	amch_vw 
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	= @MSKsequence_id 
		AND		line_id 		> @MSKline_id
	END

	SELECT @MSKsequence_id 	= MIN(sequence_id) 
	FROM 	amch_vw 
	WHERE	company_id 		= @company_id 
	AND		trx_ctrl_num 	= @trx_ctrl_num 
	AND		sequence_id 	> @MSKsequence_id

	WHILE @MSKsequence_id IS NOT NULL AND @rowsfound < @rowsrequested
	BEGIN
		SELECT 	@MSKline_id 	= MIN(line_id) 
		FROM 	amch_vw
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	= @MSKsequence_id

		WHILE @MSKline_id IS NOT NULL AND @rowsfound < @rowsrequested
	 	BEGIN

			INSERT INTO #temp 
			SELECT 
				timestamp,
				company_id,
				trx_ctrl_num,
				sequence_id,
				line_id,
				line_desc,
				gl_exp_acct,
				reference_code,
				amt_charged,
				qty_received,
				co_asset_id,
				asset_ctrl_num,
				line_description,
				quantity,
				update_asset_quantity,
				asset_amount,
				imm_exp_amount,
				imm_exp_acct,
				imm_exp_ref_code,
				create_item,
				activity_type,
				apply_date,
				asset_tag,
				item_tag,
				last_modified_date,
				modified_by
			FROM 	amch_vw 
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		= @MSKline_id

			SELECT @rowsfound = @rowsfound + @@rowcount

			

			SELECT 	@MSKline_id 	= min(line_id) 
			FROM 	amch_vw 
			WHERE	company_id 		= @company_id 
			AND		trx_ctrl_num 	= @trx_ctrl_num 
			AND		sequence_id 	= @MSKsequence_id 
			AND		line_id 		> @MSKline_id
		END
		
		
		SELECT 	@MSKsequence_id = MIN(sequence_id) 
		FROM 	amch_vw 
		WHERE	company_id 		= @company_id 
		AND		trx_ctrl_num 	= @trx_ctrl_num 
		AND		sequence_id 	> @MSKsequence_id
	END
END

SELECT
	timestamp,
	company_id,
	trx_ctrl_num,
	sequence_id,
	line_id					= ISNULL(line_id, 1),
	line_desc,
	gl_exp_acct,
	reference_code,
	amt_extended,
	qty_received,
	co_asset_id,
	asset_ctrl_num,
	line_description 		= ISNULL(line_description, line_desc),
	quantity				= ISNULL(quantity, qty_received),
	update_asset_quantity	= ISNULL(update_asset_quantity, 1),
	asset_amount			= ISNULL(asset_amount, 0.0),
	imm_exp_amount			= ISNULL(imm_exp_amount, 0.0),
	imm_exp_acct,
	imm_exp_ref_code,
	create_item				= ISNULL(create_item, 1),
	activity_type			= ISNULL(activity_type, 10),
	apply_date 				= CONVERT(char(8), apply_date, 112),
	asset_tag,
	item_tag,
	last_modified_date 		= CONVERT(char(8), last_modified_date, 112),
	modified_by
FROM #temp 
ORDER BY company_id, trx_ctrl_num, sequence_id, line_id
DROP TABLE #temp

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[amphdr_vw_amch_vwChildFetch_sp] TO [public]
GO
