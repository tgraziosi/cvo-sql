SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[apvocrd_sp] 
	@module_id              int,
	@interface_mode 		smallint,
	@trx_ctrl_num           varchar(16),
	@trx_type               smallint,
	@sequence_id            int OUTPUT,
	@location_code          varchar(8),
	@item_code              varchar(30),
	@bulk_flag              smallint,
	@qty_ordered            float,
	@qty_received           float,
	@qty_returned           float,
	@qty_prev_returned      float,
	@approval_code  		varchar(8),
	@tax_code               varchar(8),
	@return_code            varchar(8),
	@code_1099              varchar(8),
	@po_ctrl_num            varchar(16),
	@unit_code              varchar(8),
	@unit_price             float,
	@amt_discount           float,
	@amt_freight            float,
	@amt_tax                float,
	@amt_misc               float,
	@amt_extended           float,
	@calc_tax 				float,
	@date_entered           int,
	@gl_exp_acct            varchar(32),
	@new_gl_exp_acct        varchar(32),
	@rma_num                varchar(20),
	@line_desc              varchar(60),
	@serial_id              int,
	@company_id             smallint,
	@iv_post_flag           smallint,
	@po_orig_flag           smallint,
	@rec_company_code       varchar(8),
	@new_rec_company_code	varchar(8),
	@reference_code			varchar(32),
	@new_reference_code     varchar(32),
	@org_id			varchar(30) = '',		   
	@amt_nonrecoverable_tax	float = 0,			
	@amt_tax_det		float = 0			

AS

DECLARE @result                 int




IF @org_id = ''
BEGIN
	SELECT 	@org_id  = organization_id
	FROM	Organization
	WHERE	outline_num = '1'	
END








SELECT  @sequence_id = ISNULL(MAX( sequence_id ),0) + 1
FROM    #apinpcdt        
WHERE   trx_ctrl_num = @trx_ctrl_num
AND     trx_type     = @trx_type




INSERT  #apinpcdt (
	trx_ctrl_num,
	trx_type,
	sequence_id,
	location_code,
	item_code,
	bulk_flag,
	qty_ordered,
	qty_received,
	qty_returned,
	qty_prev_returned,
	approval_code,
	tax_code,
	return_code,
	code_1099,
	po_ctrl_num,
	unit_code,
	unit_price,
	amt_discount,
	amt_freight,
	amt_tax,
	amt_misc,
	amt_extended,
	calc_tax,
	date_entered,
	gl_exp_acct,
	new_gl_exp_acct,
	rma_num,
	line_desc,
	serial_id,
	company_id,
	iv_post_flag,
	po_orig_flag,
	rec_company_code,
	new_rec_company_code,
	reference_code,
	new_reference_code,
	trx_state,
	org_id,
	amt_nonrecoverable_tax,
	mark_flag,
	amt_tax_det )

VALUES (
	@trx_ctrl_num,
	@trx_type,
	@sequence_id,
	@location_code,
	@item_code,
	@bulk_flag,
	@qty_ordered,
	@qty_received,
	@qty_returned,
	@qty_prev_returned,
	@approval_code,
	@tax_code,
	@return_code,
	@code_1099,
	@po_ctrl_num,
	@unit_code,
	@unit_price,
	@amt_discount,
	@amt_freight,
	@amt_tax,
	@amt_misc,
	@amt_extended,
	@calc_tax,
	@date_entered,
	@gl_exp_acct,
	@new_gl_exp_acct,
	@rma_num,
	@line_desc,
	@serial_id,
	@company_id,
	@iv_post_flag,
	@po_orig_flag,
	@rec_company_code,
	@new_rec_company_code,
	@reference_code,
	@new_reference_code,
	0,
	@org_id,
	@amt_nonrecoverable_tax,
	0,
	@amt_tax_det
	       )

IF ( @@error != 0 )
	RETURN  -1
	
RETURN  0

GO
GRANT EXECUTE ON  [dbo].[apvocrd_sp] TO [public]
GO
